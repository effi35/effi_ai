#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
מודול מיזוג קוד למאחד קוד חכם Pro 2.0
מאפשר מיזוג מתקדם של קוד משני מקורות או יותר

מחבר: Claude AI
גרסה: 1.0.0
תאריך: מאי 2025
"""

import os
import re
import sys
import json
import shutil
import difflib
import hashlib
import tempfile
import logging
import datetime
from typing import Dict, List, Tuple, Any, Optional, Union, Set
from pathlib import Path
from functools import lru_cache
from concurrent.futures import ThreadPoolExecutor

# הגדרת לוגר זמני עד לטעינת מודול הלוגים
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(os.path.join(os.path.dirname(os.path.dirname(__file__)), 'logs', 'merger.log')),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# ניסיון לטעון את מודול הלוגים המתקדם
try:
    from core.log_manager import LogManager
    logger = LogManager(__name__).get_logger()
    logger.info("מודול לוגים מתקדם נטען בהצלחה")
except ImportError:
    logger.warning("מודול לוגים מתקדם לא נמצא, משתמש בלוגר בסיסי")

class ConflictResolutionMethod:
    """מחלקת Enum המגדירה שיטות פתרון קונפליקטים"""
    KEEP_SOURCE = "keep_source"         # השאר את קובץ המקור
    KEEP_TARGET = "keep_target"         # השאר את קובץ היעד
    KEEP_BOTH = "keep_both"             # שמור את שניהם עם שינוי שמות
    MERGE_CONTENT = "merge_content"     # מזג את התוכן של שני הקבצים
    MERGE_SMART = "merge_smart"         # מיזוג חכם עם ניתוח קוד
    AUTO = "auto"                       # בחירה אוטומטית
    PROMPT = "prompt"                   # שאל את המשתמש

class FileMergeResult:
    """מחלקה המכילה תוצאות מיזוג קובץ"""
    
    def __init__(self, source_path: str, target_path: str):
        """
        אתחול תוצאות מיזוג
        
        Args:
            source_path: נתיב הקובץ המקורי
            target_path: נתיב הקובץ היעד
        """
        self.source_path = source_path
        self.target_path = target_path
        self.success = False
        self.conflict = False
        self.conflict_resolved = False
        self.resolution_method = None
        self.conflict_details = None
        self.error = None
        self.changes_count = 0
        self.result_path = None
    
    def to_dict(self) -> Dict[str, Any]:
        """המרת התוצאה למילון"""
        return {
            "source_path": self.source_path,
            "target_path": self.target_path,
            "success": self.success,
            "conflict": self.conflict,
            "conflict_resolved": self.conflict_resolved,
            "resolution_method": self.resolution_method,
            "conflict_details": self.conflict_details,
            "error": self.error,
            "changes_count": self.changes_count,
            "result_path": self.result_path
        }

class CodeMerger:
    """
    מנהל מיזוג קוד חכם לקבצים ופרויקטים
    מאפשר מיזוג מתקדם עם זיהוי קונפליקטים, פתרון חכם, ותמיכה בשפות שונות
    """
    
    def __init__(self, config: Dict[str, Any] = None):
        """
        אתחול מנהל מיזוג הקוד
        
        Args:
            config: מילון הגדרות תצורה
        """
        # הגדרות ברירת מחדל
        default_config = {
            "conflict_resolution": ConflictResolutionMethod.AUTO,
            "create_backup": True,
            "max_workers": 4,
            "ignore_patterns": [
                "**/.git/**", "**/node_modules/**", "**/__pycache__/**", "**/.DS_Store",
                "**/.vscode/**", "**/.idea/**", "**/venv/**", "**/env/**"
            ],
            "create_zip": True,
            "keep_original_timestamps": True,
            "backup_dir": "backups",
            "language_settings": {
                "python": {
                    "conflict_markers": ["<<<<<<< SOURCE", "=======", ">>>>>>> TARGET"],
                    "indent_size": 4,
                    "comment_prefix": "#"
                },
                "javascript": {
                    "conflict_markers": ["<<<<<<< SOURCE", "=======", ">>>>>>> TARGET"],
                    "indent_size": 2,
                    "comment_prefix": "//"
                },
                "java": {
                    "conflict_markers": ["<<<<<<< SOURCE", "=======", ">>>>>>> TARGET"],
                    "indent_size": 4,
                    "comment_prefix": "//"
                },
                "default": {
                    "conflict_markers": ["<<<<<<< SOURCE", "=======", ">>>>>>> TARGET"],
                    "indent_size": 4,
                    "comment_prefix": "#"
                }
            }
        }
        
        # עדכון תצורה עם קלט המשתמש
        self.config = default_config
        if config:
            self._update_config_recursive(self.config, config)
        
        # מטמון שפות לקבצים
        self._file_language_cache = {}
        
        logger.info(f"מנהל מיזוג קוד אותחל עם הגדרות: conflict_resolution={self.config['conflict_resolution']}, "
                   f"max_workers={self.config['max_workers']}")
    
    def _update_config_recursive(self, target_dict: Dict[str, Any], update_dict: Dict[str, Any]) -> None:
        """
        עדכון רקורסיבי של מילון הגדרות
        
        Args:
            target_dict: מילון יעד
            update_dict: מילון עדכונים
        """
        for key, value in update_dict.items():
            if key in target_dict and isinstance(target_dict[key], dict) and isinstance(value, dict):
                self._update_config_recursive(target_dict[key], value)
            else:
                target_dict[key] = value
    
    def _detect_file_language(self, file_path: str) -> str:
        """
        זיהוי שפת התכנות של קובץ
        
        Args:
            file_path: נתיב הקובץ
            
        Returns:
            שפת התכנות שזוהתה או "default"
        """
        # בדיקה אם קיים במטמון
        if file_path in self._file_language_cache:
            return self._file_language_cache[file_path]
        
        # זיהוי לפי סיומת
        ext = os.path.splitext(file_path)[1].lower()
        language = "default"
        
        # מיפוי סיומות לשפות
        ext_to_language = {
            ".py": "python",
            ".pyw": "python",
            ".js": "javascript",
            ".jsx": "javascript",
            ".ts": "javascript",
            ".tsx": "javascript",
            ".java": "java",
            ".kt": "kotlin",
            ".cs": "csharp",
            ".cpp": "cpp",
            ".cc": "cpp",
            ".c": "c",
            ".h": "c",
            ".hpp": "cpp",
            ".rb": "ruby",
            ".php": "php",
            ".go": "go",
            ".swift": "swift",
            ".rs": "rust",
            ".sh": "bash",
            ".html": "html",
            ".css": "css",
            ".scss": "scss",
            ".vue": "vue",
            ".xml": "xml",
            ".json": "json",
            ".md": "markdown"
        }
        
        if ext in ext_to_language:
            language = ext_to_language[ext]
        
        # אם הסיומת לא עזרה, נסה לבדוק את תוכן הקובץ
        if language == "default" and os.path.exists(file_path):
            try:
                with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read(1024)  # קריאת רק 1KB מהקובץ לזיהוי
                
                # בדיקת תוכן הקובץ לדפוסים נפוצים
                if re.search(r'^#!/usr/bin/env python|^#!/usr/bin/python', content):
                    language = "python"
                elif re.search(r'^#!/bin/bash|^#!/usr/bin/env bash', content):
                    language = "bash"
                elif re.search(r'^<\?php', content):
                    language = "php"
                elif re.search(r'^\s*package\s+[a-z0-9_\.]+;', content):
                    language = "java"
                elif re.search(r'using System;|namespace [A-Za-z0-9_\.]+\s*{', content):
                    language = "csharp"
                elif re.search(r'<!DOCTYPE html>|<html', content):
                    language = "html"
            except:
                pass
        
        # שמירה במטמון
        self._file_language_cache[file_path] = language
        return language
    
    def _get_language_settings(self, file_path: str) -> Dict[str, Any]:
        """
        קבלת הגדרות שפה לקובץ
        
        Args:
            file_path: נתיב הקובץ
            
        Returns:
            הגדרות השפה
        """
        language = self._detect_file_language(file_path)
        settings = self.config["language_settings"].get(language)
        
        if not settings:
            settings = self.config["language_settings"]["default"]
        
        return settings
    
    def _backup_file(self, file_path: str) -> str:
        """
        יצירת גיבוי לקובץ
        
        Args:
            file_path: נתיב הקובץ לגיבוי
            
        Returns:
            נתיב קובץ הגיבוי או None אם הגיבוי נכשל
        """
        if not os.path.exists(file_path):
            return None
        
        # וידוא קיום תיקיית גיבויים
        current_dir = os.path.dirname(os.path.abspath(file_path))
        backup_dir = os.path.join(current_dir, self.config["backup_dir"])
        os.makedirs(backup_dir, exist_ok=True)
        
        # יצירת נתיב גיבוי עם חותמת זמן
        file_name = os.path.basename(file_path)
        timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_path = os.path.join(backup_dir, f"{file_name}.{timestamp}.bak")
        
        # העתקת הקובץ
        try:
            shutil.copy2(file_path, backup_path)
            logger.info(f"נוצר גיבוי: {backup_path}")
            return backup_path
        except Exception as e:
            logger.error(f"שגיאה ביצירת גיבוי לקובץ {file_path}: {str(e)}")
            return None
    
    def _should_ignore_file(self, file_path: str) -> bool:
        """
        בדיקה אם יש להתעלם מקובץ
        
        Args:
            file_path: נתיב הקובץ
            
        Returns:
            True אם יש להתעלם מהקובץ, אחרת False
        """
        # המרה לנתיב יחסי
        rel_path = file_path.replace("\\", "/")
        
        # בדיקה מול דפוסי התעלמות
        for pattern in self.config["ignore_patterns"]:
            # המרת דפוס סגנון glob לbitnami
            if "**" in pattern:
                parts = pattern.split("**")
                regex_pattern = parts[0]
                for part in parts[1:]:
                    regex_pattern += ".*" + part
                regex_pattern = f"^{regex_pattern}$".replace("*", ".*").replace("?", ".")
                
                if re.search(regex_pattern, rel_path):
                    return True
            # התאמה פשוטה
            elif pattern in rel_path:
                return True
        
        return False
    
    def _get_file_hash(self, file_path: str) -> str:
        """
        חישוב חתימת קובץ
        
        Args:
            file_path: נתיב הקובץ
            
        Returns:
            חתימת MD5 של תוכן הקובץ
        """
        if not os.path.exists(file_path):
            return ""
        
        try:
            with open(file_path, 'rb') as f:
                return hashlib.md5(f.read()).hexdigest()
        except Exception as e:
            logger.error(f"שגיאה בחישוב חתימת קובץ {file_path}: {str(e)}")
            return ""
    
    def _read_file_content(self, file_path: str) -> Tuple[str, str]:
        """
        קריאת תוכן קובץ
        
        Args:
            file_path: נתיב הקובץ
            
        Returns:
            טאפל עם תוכן הקובץ וקידוד התווים
        """
        if not os.path.exists(file_path):
            return "", "utf-8"
        
        # ניסיון לזהות את הקידוד
        encodings = ['utf-8', 'utf-16', 'windows-1255', 'iso-8859-8', 'cp1255']
        
        for encoding in encodings:
            try:
                with open(file_path, 'r', encoding=encoding) as f:
                    content = f.read()
                return content, encoding
            except UnicodeDecodeError:
                continue
        
        # אם כל הניסיונות נכשלו, נקרא כבינארי
        try:
            with open(file_path, 'rb') as f:
                binary_content = f.read()
            return binary_content.decode('utf-8', errors='ignore'), 'utf-8'
        except Exception as e:
            logger.error(f"שגיאה בקריאת קובץ {file_path}: {str(e)}")
            return "", "utf-8"
    
    def _write_file_content(self, file_path: str, content: str, encoding: str = 'utf-8') -> bool:
        """
        כתיבת תוכן לקובץ
        
        Args:
            file_path: נתיב הקובץ
            content: תוכן לכתיבה
            encoding: קידוד תווים
            
        Returns:
            True אם הכתיבה הצליחה, אחרת False
        """
        try:
            # וידוא קיום תיקיית היעד
            os.makedirs(os.path.dirname(file_path), exist_ok=True)
            
            with open(file_path, 'w', encoding=encoding) as f:
                f.write(content)
            return True
        except Exception as e:
            logger.error(f"שגיאה בכתיבת קובץ {file_path}: {str(e)}")
            return False
    
    def merge_files(self, source_path: str, target_path: str, 
                    resolution_method: str = None) -> FileMergeResult:
        """
        מיזוג של שני קבצים
        
        Args:
            source_path: נתיב קובץ המקור
            target_path: נתיב קובץ היעד
            resolution_method: שיטת פתרון קונפליקטים
            
        Returns:
            תוצאת המיזוג
        """
        result = FileMergeResult(source_path, target_path)
        
        # בדיקה שהקבצים קיימים
        if not os.path.exists(source_path):
            result.error = f"קובץ המקור {source_path} לא נמצא"
            logger.error(result.error)
            return result
        
        # בדיקה אם יש להתעלם מהקובץ
        if self._should_ignore_file(source_path):
            logger.info(f"מתעלם מקובץ: {source_path}")
            result.success = True
            result.result_path = target_path
            return result
        
        # קביעת שיטת פתרון קונפליקטים
        if not resolution_method:
            resolution_method = self.config["conflict_resolution"]
        
        # יצירת תיקיית היעד אם לא קיימת
        os.makedirs(os.path.dirname(target_path), exist_ok=True)
        
        # בדיקה אם הקובץ זהה (או שקובץ היעד לא קיים)
        source_hash = self._get_file_hash(source_path)
        target_hash = self._get_file_hash(target_path)
        
        # אם קובץ היעד לא קיים, פשוט העתק
        if not os.path.exists(target_path):
            try:
                # העתקת הקובץ
                shutil.copy2(source_path, target_path)
                
                result.success = True
                result.result_path = target_path
                logger.info(f"הקובץ {source_path} הועתק ליעד {target_path}")
                return result
            except Exception as e:
                result.error = f"שגיאה בהעתקת קובץ {source_path} ליעד {target_path}: {str(e)}"
                logger.error(result.error)
                return result
        
        # אם הקבצים זהים, אין צורך במיזוג
        if source_hash == target_hash:
            result.success = True
            result.result_path = target_path
            logger.info(f"הקבצים {source_path} ו-{target_path} זהים, לא נדרש מיזוג")
            return result
        
        # יצירת גיבוי לקובץ היעד אם צריך
        if self.config["create_backup"]:
            self._backup_file(target_path)
        
        # זיהוי שפת התכנות וקבלת הגדרות
        language_settings = self._get_language_settings(source_path)
        
        try:
            # קריאת תוכן הקבצים
            source_content, source_encoding = self._read_file_content(source_path)
            target_content, target_encoding = self._read_file_content(target_path)
            
            # בחירת שיטת פתרון קונפליקטים
            result.conflict = True
            result.resolution_method = resolution_method
            merged_content = None
            
            # החלטה על שיטת המיזוג לפי סוג הקובץ וגודלו
            if resolution_method == ConflictResolutionMethod.AUTO:
                # בדיקה אם קובץ בינארי
                is_binary = "\0" in source_content[:1024] or "\0" in target_content[:1024]
                
                if is_binary:
                    # בקבצים בינאריים, נשמור את הגרסה החדשה יותר
                    source_mtime = os.path.getmtime(source_path)
                    target_mtime = os.path.getmtime(target_path)
                    
                    if source_mtime > target_mtime:
                        resolution_method = ConflictResolutionMethod.KEEP_SOURCE
                    else:
                        resolution_method = ConflictResolutionMethod.KEEP_TARGET
                else:
                    # קבצי טקסט - ננסה מיזוג חכם
                    resolution_method = ConflictResolutionMethod.MERGE_SMART
            
            # ביצוע המיזוג לפי השיטה שנבחרה
            if resolution_method == ConflictResolutionMethod.KEEP_SOURCE:
                merged_content = source_content
                result.changes_count = 1
                logger.info(f"שמירת קובץ המקור {source_path}")
                
            elif resolution_method == ConflictResolutionMethod.KEEP_TARGET:
                merged_content = target_content
                result.changes_count = 0
                logger.info(f"שמירת קובץ היעד {target_path}")
                
            elif resolution_method == ConflictResolutionMethod.KEEP_BOTH:
                # שמירת שני הקבצים עם שמות שונים
                file_name, file_ext = os.path.splitext(target_path)
                source_new_path = f"{file_name}.source{file_ext}"
                target_new_path = f"{file_name}.target{file_ext}"
                
                # כתיבת הקבצים
                self._write_file_content(source_new_path, source_content, source_encoding)
                self._write_file_content(target_new_path, target_content, target_encoding)
                
                # עדכון תוצאה
                result.success = True
                result.conflict_resolved = True
                result.result_path = f"{source_new_path}, {target_new_path}"
                result.changes_count = 2
                
                logger.info(f"שמירת שני הקבצים: {source_new_path}, {target_new_path}")
                return result
                
            elif resolution_method == ConflictResolutionMethod.MERGE_CONTENT:
                # מיזוג פשוט עם סימוני קונפליקט
                merged_content = self._simple_merge_content(source_content, target_content, language_settings)
                result.changes_count = 1
                logger.info(f"ביצוע מיזוג תוכן בסיסי")
                
            elif resolution_method == ConflictResolutionMethod.MERGE_SMART:
                # מיזוג חכם עם ניתוח תוכן
                merged_content, changes = self._smart_merge_content(source_content, target_content, language_settings, source_path)
                result.changes_count = changes
                logger.info(f"ביצוע מיזוג חכם עם {changes} שינויים")
                
            elif resolution_method == ConflictResolutionMethod.PROMPT:
                # במקרה של PROMPT, נחזיר תוצאת קונפליקט ללא פתרון
                result.conflict = True
                result.conflict_resolved = False
                result.conflict_details = {
                    "source_content": source_content,
                    "target_content": target_content,
                    "source_path": source_path,
                    "target_path": target_path
                }
                return result
            
            # שמירת התוצאה לקובץ היעד
            if merged_content is not None:
                # שמירת זמני יצירה ושינוי מקוריים אם צריך
                original_times = None
                if self.config["keep_original_timestamps"] and os.path.exists(target_path):
                    original_times = (os.path.getatime(target_path), os.path.getmtime(target_path))
                
                # כתיבת התוכן הממוזג
                if self._write_file_content(target_path, merged_content, target_encoding):
                    # שחזור זמנים מקוריים
                    if original_times:
                        os.utime(target_path, original_times)
                    
                    result.success = True
                    result.conflict_resolved = True
                    result.result_path = target_path
                else:
                    result.error = f"שגיאה בכתיבת קובץ היעד {target_path}"
            else:
                result.error = "לא נוצר תוכן ממוזג"
        
        except Exception as e:
            result.error = f"שגיאה במיזוג קבצים: {str(e)}"
            logger.error(f"שגיאה במיזוג {source_path} ו-{target_path}: {str(e)}")
        
        return result
    
    def _simple_merge_content(self, source_content: str, target_content: str, 
                             language_settings: Dict[str, Any]) -> str:
        """
        מיזוג פשוט של תוכן עם סימוני קונפליקט
        
        Args:
            source_content: תוכן קובץ המקור
            target_content: תוכן קובץ היעד
            language_settings: הגדרות שפה
            
        Returns:
            התוכן הממוזג
        """
        # פיצול לשורות
        source_lines = source_content.splitlines()
        target_lines = target_content.splitlines()
        
        # יצירת סימוני קונפליקט
        conflict_markers = language_settings["conflict_markers"]
        
        # בניית תוכן ממוזג
        merged_lines = []
        merged_lines.append(conflict_markers[0])
        merged_lines.extend(source_lines)
        merged_lines.append(conflict_markers[1])
        merged_lines.extend(target_lines)
        merged_lines.append(conflict_markers[2])
        
        return "\n".join(merged_lines)
    
    def _smart_merge_content(self, source_content: str, target_content: str, 
                            language_settings: Dict[str, Any], file_path: str) -> Tuple[str, int]:
        """
        מיזוג חכם של תוכן עם זיהוי שינויים
        
        Args:
            source_content: תוכן קובץ המקור
            target_content: תוכן קובץ היעד
            language_settings: הגדרות שפה
            file_path: נתיב הקובץ המקורי
            
        Returns:
            טאפל עם התוכן הממוזג ומספר השינויים
        """
        # פיצול לשורות
        source_lines = source_content.splitlines()
        target_lines = target_content.splitlines()
        
        # סימוני קונפליקט
        conflict_markers = language_settings["conflict_markers"]
        
        # חישוב ההבדלים
        differ = difflib.Differ()
        diff = list(differ.compare(target_lines, source_lines))
        
        # בניית תוכן ממוזג
        merged_lines = []
        changes_count = 0
        in_conflict = False
        conflict_lines = []
        
        # זיהוי שפה לקבלת תחביר הערות
        comment_prefix = language_settings["comment_prefix"]
        
        for line in diff:
            # שורות זהות
            if line.startswith("  "):
                # אם היינו בקונפליקט, נפתור אותו
                if in_conflict:
                    merged_lines.extend(self._resolve_conflict_section(conflict_lines, language_settings))
                    conflict_lines = []
                    in_conflict = False
                    changes_count += 1
                
                # הוספת השורה הזהה
                merged_lines.append(line[2:])
                
            # שורות שנוספו במקור
            elif line.startswith("+ "):
                # סימון קטע קונפליקט
                if not in_conflict:
                    in_conflict = True
                
                conflict_lines.append(("source", line[2:]))
                
            # שורות שנמחקו (קיימות רק ביעד)
            elif line.startswith("- "):
                # סימון קטע קונפליקט
                if not in_conflict:
                    in_conflict = True
                
                conflict_lines.append(("target", line[2:]))
                
            # שורות עם סימון שינוי
            elif line.startswith("? "):
                continue
        
        # טיפול בקונפליקט אחרון אם יש
        if in_conflict:
            merged_lines.extend(self._resolve_conflict_section(conflict_lines, language_settings))
            changes_count += 1
        
        # בדיקת תקינות התוצאה לפי סוג הקובץ
        merged_content = "\n".join(merged_lines)
        
        # החלפת סיומת שורה לפי המקור
        if "\r\n" in source_content:
            merged_content = merged_content.replace("\n", "\r\n")
        
        return merged_content, changes_count
    
    def _resolve_conflict_section(self, conflict_lines: List[Tuple[str, str]], 
                                 language_settings: Dict[str, Any]) -> List[str]:
        """
        פתרון קונפליקט בקטע קוד
        
        Args:
            conflict_lines: רשימת שורות בקונפליקט
            language_settings: הגדרות שפה
            
        Returns:
            רשימת שורות לאחר פתרון
        """
        # פיצול לשורות מקור ויעד
        source_lines = [line for src, line in conflict_lines if src == "source"]
        target_lines = [line for src, line in conflict_lines if src == "target"]
        
        # בדיקת מקרים פשוטים
        if not source_lines:
            return target_lines
        elif not target_lines:
            return source_lines
            
        # סימוני קונפליקט והערות
        markers = language_settings["conflict_markers"]
        comment = language_settings["comment_prefix"]
        
        # ניתוח חכם לפי תוכן השורות
        if self._is_import_section(source_lines, target_lines):
            # מיזוג ייחודי של הצהרות ייבוא
            return self._merge_imports(source_lines, target_lines)
        elif self._is_function_declaration(source_lines, target_lines):
            # בדיקה אם יש שינוי בחתימת פונקציה
            # במקרה זה, נעדיף את הקוד החדש יותר (source)
            return source_lines
        elif len(source_lines) == 1 and len(target_lines) == 1 and self._is_simple_variable(source_lines[0], target_lines[0]):
            # במקרה של הגדרת משתנה פשוטה, נשתמש במקור
            return source_lines
        else:
            # במקרים מורכבים יותר, נסמן את הקונפליקט
            result = []
            result.append(f"{comment} {markers[0]}")
            for line in source_lines:
                result.append(line)
            result.append(f"{comment} {markers[1]}")
            for line in target_lines:
                result.append(line)
            result.append(f"{comment} {markers[2]}")
            return result
    
    def _is_import_section(self, source_lines: List[str], target_lines: List[str]) -> bool:
        """
        בדיקה אם מדובר בקטע ייבוא (import)
        
        Args:
            source_lines: שורות מקור
            target_lines: שורות יעד
            
        Returns:
            True אם מדובר בקטע ייבוא
        """
        # בדיקת תבנית import בשפות שונות
        import_patterns = [
            r"^\s*import\s+[\w\.]+",  # Python, Java
            r"^\s*from\s+[\w\.]+\s+import",  # Python
            r"^\s*require\s*\(['\"][\w\-\.\/]+['\"]\)",  # Node.js
            r"^\s*#include\s+[<\"][\w\.\/]+[>\"]",  # C/C++
            r"^\s*using\s+[\w\.]+;",  # C#
            r"^\s*import\s+{.+}\s+from",  # ES6
        ]
        
        source_imports = sum(1 for line in source_lines 
                           if any(re.match(pattern, line) for pattern in import_patterns))
        target_imports = sum(1 for line in target_lines 
                           if any(re.match(pattern, line) for pattern in import_patterns))
        
        # אם רוב השורות הן הצהרות ייבוא
        source_ratio = source_imports / max(1, len(source_lines))
        target_ratio = target_imports / max(1, len(target_lines))
        
        return (source_ratio > 0.5 and target_ratio > 0.5)
    
    def _merge_imports(self, source_lines: List[str], target_lines: List[str]) -> List[str]:
        """
        מיזוג של הצהרות ייבוא
        
        Args:
            source_lines: שורות מקור
            target_lines: שורות יעד
            
        Returns:
            רשימת שורות לאחר מיזוג
        """
        # איחוד של הצהרות הייבוא (ללא כפילויות)
        unique_imports = set()
        
        for line in source_lines + target_lines:
            # דילוג על שורות ריקות והערות
            stripped = line.strip()
            if not stripped or stripped.startswith('#') or stripped.startswith('//'):
                continue
            
            unique_imports.add(line)
        
        # מיון הצהרות הייבוא לקבוצות (לפי סוג)
        standard_libs = []
        third_party = []
        local_imports = []
        
        for imp in unique_imports:
            if any(pattern in imp for pattern in ['"', "'"]):
                if "./" in imp or "../" in imp:
                    local_imports.append(imp)
                else:
                    third_party.append(imp)
            else:
                standard_libs.append(imp)
        
        # מיון פנימי בכל קבוצה
        standard_libs.sort()
        third_party.sort()
        local_imports.sort()
        
        # בניית הרשימה הסופית
        result = []
        if standard_libs:
            result.extend(standard_libs)
            result.append("")
        if third_party:
            result.extend(third_party)
            result.append("")
        if local_imports:
            result.extend(local_imports)
        
        return result
    
    def _is_function_declaration(self, source_lines: List[str], target_lines: List[str]) -> bool:
        """
        בדיקה אם מדובר בהצהרת פונקציה
        
        Args:
            source_lines: שורות מקור
            target_lines: שורות יעד
            
        Returns:
            True אם מדובר בהצהרת פונקציה
        """
        # תבניות להצהרת פונקציה בשפות שונות
        function_patterns = [
            r"^\s*def\s+\w+\s*\(",  # Python
            r"^\s*function\s+\w+\s*\(",  # JavaScript
            r"^\s*\w+\s+\w+\s*\([^\)]*\)\s*{",  # Java/C++/C#
            r"^\s*public|private|protected\s+\w+\s+\w+\s*\(",  # Java/C#
            r"^\s*\(\s*\w+\s*\)\s*=>",  # Arrow function (JS)
        ]
        
        # בדיקת שורה ראשונה בכל קבוצה
        if source_lines and target_lines:
            source_match = any(re.match(pattern, source_lines[0]) for pattern in function_patterns)
            target_match = any(re.match(pattern, target_lines[0]) for pattern in function_patterns)
            
            return source_match and target_match
        
        return False
    
    def _is_simple_variable(self, source_line: str, target_line: str) -> bool:
        """
        בדיקה אם מדובר בהגדרת משתנה פשוטה
        
        Args:
            source_line: שורת מקור
            target_line: שורת יעד
            
        Returns:
            True אם מדובר בהגדרת משתנה פשוטה
        """
        # תבניות להגדרת משתנה בשפות שונות
        variable_patterns = [
            r"^\s*\w+\s*=",  # Python, JavaScript
            r"^\s*var|let|const\s+\w+\s*=",  # JavaScript
            r"^\s*\w+\s+\w+\s*=",  # Java, C#, C++
        ]
        
        source_match = any(re.match(pattern, source_line) for pattern in variable_patterns)
        target_match = any(re.match(pattern, target_line) for pattern in variable_patterns)
        
        # בדיקה שמדובר באותו משתנה
        if source_match and target_match:
            # חילוץ שם המשתנה
            source_var = re.search(r"^\s*(?:var|let|const)?\s*(\w+)\s*=", source_line)
            target_var = re.search(r"^\s*(?:var|let|const)?\s*(\w+)\s*=", target_line)
            
            if source_var and target_var and source_var.group(1) == target_var.group(1):
                return True
        
        return False
    
    def merge_project_files(self, source_files: List[str], target_dir: str, 
                          resolution_method: str = None) -> Dict[str, Any]:
        """
        מיזוג של קבצי פרויקט לתיקיית יעד
        
        Args:
            source_files: רשימת נתיבי קבצי מקור
            target_dir: תיקיית יעד
            resolution_method: שיטת פתרון קונפליקטים
            
        Returns:
            מילון עם תוצאות המיזוג
        """
        if not os.path.exists(target_dir):
            os.makedirs(target_dir, exist_ok=True)
        
        # הכנת תוצאות
        results = {
            "success": True,
            "merged_files": [],
            "failed_files": [],
            "skipped_files": [],
            "conflicts": [],
            "total_files": len(source_files),
            "total_changes": 0
        }
        
        # הגדרת מספר העובדים למקביליות
        with ThreadPoolExecutor(max_workers=self.config["max_workers"]) as executor:
            # הכנת משימות מיזוג
            merge_tasks = []
            
            for source_path in source_files:
                # חישוב נתיב יעד יחסי
                common_prefix = os.path.commonprefix([os.path.dirname(p) for p in source_files])
                if common_prefix:
                    relative_path = os.path.relpath(source_path, common_prefix)
                else:
                    relative_path = os.path.basename(source_path)
                
                target_path = os.path.join(target_dir, relative_path)
                
                # הוספת משימת מיזוג
                merge_tasks.append(executor.submit(self.merge_files, source_path, target_path, resolution_method))
            
            # איסוף תוצאות
            for task in merge_tasks:
                result = task.result()
                
                if result.error:
                    results["success"] = False
                    results["failed_files"].append({
                        "source": result.source_path,
                        "target": result.target_path,
                        "error": result.error
                    })
                elif result.conflict and not result.conflict_resolved:
                    results["conflicts"].append({
                        "source": result.source_path,
                        "target": result.target_path,
                        "details": result.conflict_details
                    })
                elif result.success:
                    results["merged_files"].append({
                        "source": result.source_path,
                        "target": result.target_path,
                        "changes": result.changes_count
                    })
                    results["total_changes"] += result.changes_count
                else:
                    results["skipped_files"].append({
                        "source": result.source_path,
                        "target": result.target_path
                    })
        
        # סיכום
        results["success_count"] = len(results["merged_files"])
        results["failure_count"] = len(results["failed_files"])
        results["conflict_count"] = len(results["conflicts"])
        results["skipped_count"] = len(results["skipped_files"])
        
        return results
    
    def merge_projects(self, source_dirs: List[str], target_dir: str, 
                     resolution_method: str = None) -> Dict[str, Any]:
        """
        מיזוג של פרויקטים שלמים
        
        Args:
            source_dirs: רשימת נתיבי תיקיות מקור
            target_dir: תיקיית יעד
            resolution_method: שיטת פתרון קונפליקטים
            
        Returns:
            מילון עם תוצאות המיזוג
        """
        if not os.path.exists(target_dir):
            os.makedirs(target_dir, exist_ok=True)
        
        # איסוף קבצים מכל תיקיות המקור
        all_source_files = []
        
        for source_dir in source_dirs:
            if not os.path.exists(source_dir) or not os.path.isdir(source_dir):
                logger.error(f"תיקיית מקור לא קיימת: {source_dir}")
                continue
            
            # עבור על כל הקבצים בתיקייה
            for root, _, files in os.walk(source_dir):
                # בדיקה אם יש להתעלם מהתיקייה
                if self._should_ignore_file(root):
                    continue
                
                for file in files:
                    file_path = os.path.join(root, file)
                    
                    # בדיקה אם יש להתעלם מהקובץ
                    if self._should_ignore_file(file_path):
                        continue
                    
                    all_source_files.append(file_path)
        
        # מיזוג הקבצים
        return self.merge_project_files(all_source_files, target_dir, resolution_method)
    
    def resolve_merge_conflict(self, conflict_id: str, resolution: str) -> Dict[str, Any]:
        """
        פתרון קונפליקט מיזוג ידנית
        
        Args:
            conflict_id: מזהה הקונפליקט
            resolution: תוכן הפתרון
            
        Returns:
            תוצאת הפתרון
        """
        # קוד לפתרון ידני של קונפליקטים
        # (משמש בממשק משתמש אינטראקטיבי)
        return {"status": "not_implemented", "message": "פתרון קונפליקטים ידני לא הושלם עדיין"}
