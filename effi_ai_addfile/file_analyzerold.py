#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
מודול לניתוח קבצים למאחד קוד חכם Pro 2.0
ביצוע ניתוח מעמיק של קבצי קוד, זיהוי מבנים, תלויות וקשרים

מחבר: Claude AI
גרסה: 1.0.0
תאריך: מאי 2025
"""

import os
import re
import json
import ast
import logging
import tempfile
import concurrent.futures
import chardet
import pygments
import pygments.lexers
import pygments.token
import networkx as nx
from pathlib import Path
from typing import Dict, List, Tuple, Any, Optional, Union, Set, Generator
from collections import defaultdict
import importlib
import hashlib
import time

# הגדרת לוגר מודול
logger = logging.getLogger(__name__)

class FileAnalyzer:
    """
    מנתח מתקדם לקבצי קוד
    מאפשר ניתוח מעמיק של תוכן קבצי קוד, זיהוי מבנים, תלויות וקשרים בין קבצים
    """
    
    def __init__(self, config: Dict[str, Any] = None):
        """
        אתחול מנתח הקבצים
        
        Args:
            config: הגדרות קונפיגורציה אופציונליות
        """
        # הגדרות ברירת מחדל
        self.default_config = {
            "max_file_size_mb": 100,
            "skip_binary_files": True,
            "parallel_processing": True,
            "max_workers": os.cpu_count() or 4,
            "encoding_detection": True,
            "default_encoding": "utf-8",
            "detect_license": True,
            "detailed_analysis": True,
            "log_level": logging.INFO,
            "supported_languages": [
                "python", "javascript", "typescript", "java", "c", "cpp", 
                "csharp", "go", "ruby", "php", "rust", "html", "css", "swift",
                "kotlin", "scala", "shell"
            ],
            "language_patterns": {
                "python": r"\.py$",
                "javascript": r"\.js$",
                "typescript": r"\.ts$|\.tsx$",
                "java": r"\.java$",
                "c": r"\.c$|\.h$",
                "cpp": r"\.cpp$|\.hpp$|\.cc$|\.hh$",
                "csharp": r"\.cs$",
                "go": r"\.go$",
                "ruby": r"\.rb$",
                "php": r"\.php$",
                "rust": r"\.rs$",
                "html": r"\.html$|\.htm$",
                "css": r"\.css$|\.scss$|\.sass$",
                "swift": r"\.swift$",
                "kotlin": r"\.kt$",
                "scala": r"\.scala$",
                "shell": r"\.sh$|\.bash$"
            },
            "import_patterns": {
                "python": [
                    (r"^\s*import\s+([a-zA-Z0-9_.]+)", "standard"),
                    (r"^\s*from\s+([a-zA-Z0-9_.]+)\s+import", "standard"),
                    (r"__import__\(['\"]([a-zA-Z0-9_.]+)['\"]\)", "dynamic")
                ],
                "javascript": [
                    (r"^\s*import\s+.*\s+from\s+['\"]([^'\"]+)['\"]", "es6"),
                    (r"^\s*import\s+['\"]([^'\"]+)['\"]", "es6"),
                    (r"require\(\s*['\"]([^'\"]+)['\"]", "commonjs")
                ],
                "java": [
                    (r"^\s*import\s+([a-zA-Z0-9_.]+)(?:\.[*])?;", "standard")
                ],
                "go": [
                    (r'^\s*import\s+[(\s]*["\']([^"\']+)["\']', "standard")
                ]
            },
            "complexity_metrics": {
                "enable": True,
                "cyclomatic_threshold_warn": 10,
                "cyclomatic_threshold_error": 20,
                "max_nesting_depth": 5
            }
        }
        
        # עדכון הגדרות מהקונפיגורציה שסופקה
        self.config = self.default_config.copy()
        if config:
            self.config.update(config)
        
        # הגדרת רמת לוג
        logger.setLevel(self.config["log_level"])
        
        # מטמון ניתוח הקוד
        self._analysis_cache = {}
        
        # מטמון סוגי קבצים
        self._file_types_cache = {}
        
        # מילון לקסרים לשפות שונות
        self._lexers_cache = {}
        
        logger.info(f"מנתח קבצים אותחל עם {len(self.config['supported_languages'])} שפות נתמכות")
    
    def analyze_file(self, file_path: str, cache: bool = True) -> Dict[str, Any]:
        """
        ניתוח של קובץ בודד
        
        Args:
            file_path: נתיב לקובץ לניתוח
            cache: האם לשמור את התוצאות במטמון
            
        Returns:
            מילון עם תוצאות הניתוח
        """
        start_time = time.time()
        file_path = os.path.abspath(file_path)
        
        # בדיקה אם הקובץ קיים
        if not os.path.exists(file_path) or not os.path.isfile(file_path):
            logger.error(f"הקובץ {file_path} לא קיים או אינו קובץ רגיל")
            return {"error": "file_not_found", "path": file_path}
        
        # בדיקה אם הקובץ גדול מדי
        file_size_mb = os.path.getsize(file_path) / (1024 * 1024)
        if file_size_mb > self.config["max_file_size_mb"]:
            logger.warning(f"הקובץ {file_path} גדול מדי ({file_size_mb:.2f} MB)")
            return {
                "path": file_path,
                "size_mb": file_size_mb,
                "error": "file_too_large",
                "analysis": {
                    "filename": os.path.basename(file_path),
                    "extension": os.path.splitext(file_path)[1],
                    "size_bytes": os.path.getsize(file_path),
                    "type": self._detect_file_type(file_path)
                }
            }
        
        # בדיקה אם תוצאות הניתוח קיימות במטמון
        cache_key = self._get_file_hash(file_path)
        if cache and cache_key in self._analysis_cache:
            logger.debug(f"השימוש בתוצאות מטמון עבור {file_path}")
            return self._analysis_cache[cache_key]
        
        try:
            # מידע בסיסי על הקובץ
            file_stats = os.stat(file_path)
            file_info = {
                "path": file_path,
                "filename": os.path.basename(file_path),
                "extension": os.path.splitext(file_path)[1].lower(),
                "size_bytes": file_stats.st_size,
                "size_mb": file_size_mb,
                "created_at": file_stats.st_ctime,
                "modified_at": file_stats.st_mtime,
                "accessed_at": file_stats.st_atime
            }
            
            # זיהוי סוג הקובץ
            file_type = self._detect_file_type(file_path)
            file_info["type"] = file_type
            
            # אם זה קובץ בינארי וסימן לדלג על קבצים בינאריים
            if file_type == "binary" and self.config["skip_binary_files"]:
                logger.info(f"דילוג על קובץ בינארי: {file_path}")
                return {
                    "path": file_path,
                    "analysis": file_info,
                    "skipped": True,
                    "reason": "binary_file"
                }
            
            # זיהוי שפת התכנות
            language = self._detect_language(file_path)
            file_info["language"] = language
            
            # זיהוי קידוד
            if self.config["encoding_detection"]:
                encoding = self._detect_encoding(file_path)
                file_info["encoding"] = encoding
            else:
                encoding = self.config["default_encoding"]
                file_info["encoding"] = encoding
            
            # קריאת תוכן הקובץ
            try:
                with open(file_path, 'r', encoding=encoding, errors='replace') as f:
                    content = f.read()
                file_info["read_success"] = True
            except Exception as e:
                logger.warning(f"שגיאה בקריאת קובץ {file_path}: {e}")
                content = ""
                file_info["read_success"] = False
                file_info["read_error"] = str(e)
            
            # ניתוח מפורט של הקובץ לפי השפה
            if self.config["detailed_analysis"] and content and language in self.config["supported_languages"]:
                analysis_result = self._analyze_by_language(file_path, content, language)
                file_info.update(analysis_result)
            
            # ניתוח רישיון
            if self.config["detect_license"] and content:
                license_info = self._detect_license(content)
                if license_info:
                    file_info["license"] = license_info
            
            # חישוב מדדי מורכבות
            if self.config["complexity_metrics"]["enable"] and content and language:
                complexity_metrics = self._calculate_complexity_metrics(content, language)
                file_info["complexity"] = complexity_metrics
            
            # חישוב זמן הניתוח
            analysis_time = time.time() - start_time
            file_info["analysis_time"] = analysis_time
            
            # שמירה במטמון
            if cache:
                self._analysis_cache[cache_key] = file_info
            
            logger.info(f"ניתוח הקובץ {file_path} הושלם בהצלחה ({analysis_time:.2f} שניות)")
            return file_info
            
        except Exception as e:
            logger.error(f"שגיאה בניתוח {file_path}: {str(e)}", exc_info=True)
            return {
                "path": file_path,
                "error": "analysis_error",
                "error_details": str(e),
                "analysis": {
                    "filename": os.path.basename(file_path),
                    "extension": os.path.splitext(file_path)[1],
                    "size_bytes": os.path.getsize(file_path),
                    "type": self._detect_file_type(file_path)
                }
            }
    
    def analyze_files(self, file_paths: List[str], parallel: bool = None) -> Dict[str, Any]:
        """
        ניתוח של מספר קבצים במקביל
        
        Args:
            file_paths: רשימת נתיבים לקבצים לניתוח
            parallel: האם לבצע ניתוח במקביל
            
        Returns:
            מילון עם תוצאות הניתוח
        """
        if parallel is None:
            parallel = self.config["parallel_processing"]
        
        start_time = time.time()
        logger.info(f"מתחיל ניתוח של {len(file_paths)} קבצים (parallel={parallel})")
        
        results = {}
        
        if parallel and len(file_paths) > 1:
            # ניתוח במקביל
            max_workers = min(self.config["max_workers"], len(file_paths))
            with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
                future_to_file = {executor.submit(self.analyze_file, file_path): file_path for file_path in file_paths}
                for future in concurrent.futures.as_completed(future_to_file):
                    file_path = future_to_file[future]
                    try:
                        result = future.result()
                        results[file_path] = result
                    except Exception as e:
                        logger.error(f"שגיאה בניתוח מקבילי של {file_path}: {str(e)}")
                        results[file_path] = {
                            "path": file_path,
                            "error": "parallel_analysis_error",
                            "error_details": str(e)
                        }
        else:
            # ניתוח טורי
            for file_path in file_paths:
                result = self.analyze_file(file_path)
                results[file_path] = result
        
        total_time = time.time() - start_time
        
        # יצירת סיכום
        summary = {
            "total_files": len(file_paths),
            "successful_analyses": sum(1 for r in results.values() if "error" not in r),
            "failed_analyses": sum(1 for r in results.values() if "error" in r),
            "skipped_files": sum(1 for r in results.values() if r.get("skipped", False)),
            "total_time": total_time,
            "average_time_per_file": total_time / len(file_paths) if file_paths else 0
        }
        
        # התפלגות לפי שפה
        language_distribution = defaultdict(int)
        for result in results.values():
            if "analysis" in result and "language" in result["analysis"]:
                language = result["analysis"]["language"] or "unknown"
                language_distribution[language] += 1
            elif "language" in result:
                language = result["language"] or "unknown"
                language_distribution[language] += 1
        
        summary["language_distribution"] = dict(language_distribution)
        
        logger.info(f"ניתוח {len(file_paths)} קבצים הושלם ב-{total_time:.2f} שניות")
        
        return {
            "results": results,
            "summary": summary
        }
    
    def analyze_relationships(self, file_paths: List[str]) -> Dict[str, Any]:
        """
        ניתוח קשרים בין קבצים
        
        Args:
            file_paths: רשימת נתיבים לקבצים לניתוח
            
        Returns:
            מילון עם תוצאות ניתוח הקשרים
        """
        logger.info(f"מנתח קשרים בין {len(file_paths)} קבצים")
        
        # ניתוח כל הקבצים תחילה
        analysis_results = self.analyze_files(file_paths)
        
        # יצירת גרף כיווני לייצוג הקשרים
        graph = nx.DiGraph()
        
        # הוספת קודקודים (קבצים) לגרף
        for file_path in file_paths:
            file_name = os.path.basename(file_path)
            graph.add_node(file_path, name=file_name)
        
        # הוספת קשתות (תלויות) לגרף
        for file_path, result in analysis_results["results"].items():
            if "error" in result or result.get("skipped", False):
                continue
                
            # חילוץ תלויות מהקובץ
            dependencies = []
            
            # תלויות ישירות מהניתוח
            if "dependencies" in result:
                direct_deps = result["dependencies"]
                if isinstance(direct_deps, list):
                    dependencies.extend(direct_deps)
                elif isinstance(direct_deps, dict):
                    for dep_list in direct_deps.values():
                        dependencies.extend(dep_list)
            
            # תלויות מיובאים
            if "imports" in result:
                for imp in result["imports"]:
                    if isinstance(imp, dict) and "source" in imp:
                        dependencies.append(imp["source"])
                    elif isinstance(imp, str):
                        dependencies.append(imp)
            
            # המרת שמות תלויות לנתיבי קבצים מלאים
            for dependency in dependencies:
                # חיפוש קובץ מתאים ברשימת הקבצים
                matching_files = self._find_matching_files(dependency, file_paths, file_path)
                
                for target_file in matching_files:
                    if target_file != file_path:  # מניעת לולאות עצמיות
                        graph.add_edge(file_path, target_file)
        
        # חישוב מדדים על הגרף
        metrics = {}
        
        try:
            # מדד קישוריות
            metrics["connectivity"] = nx.number_strongly_connected_components(graph)
            
            # צפיפות הגרף
            metrics["density"] = nx.density(graph)
            
            # מדד מרכזיות
            metrics["centrality"] = {
                "degree": dict(nx.degree_centrality(graph)),
                "closeness": dict(nx.closeness_centrality(graph)),
                "betweenness": dict(nx.betweenness_centrality(graph))
            }
            
            # התפלגות דרגות
            in_degrees = dict(graph.in_degree())
            out_degrees = dict(graph.out_degree())
            metrics["degrees"] = {
                "in_degrees": in_degrees,
                "out_degrees": out_degrees,
                "avg_in_degree": sum(in_degrees.values()) / len(in_degrees) if in_degrees else 0,
                "avg_out_degree": sum(out_degrees.values()) / len(out_degrees) if out_degrees else 0,
                "max_in_degree": max(in_degrees.values()) if in_degrees else 0,
                "max_out_degree": max(out_degrees.values()) if out_degrees else 0
            }
            
            # זיהוי צמתים מרכזיים (hubs and authorities)
            if len(graph.nodes()) > 0:
                hub_scores, authority_scores = nx.hits(graph)
                metrics["hubs"] = dict(hub_scores)
                metrics["authorities"] = dict(authority_scores)
                
                # זיהוי הצמתים החשובים ביותר
                top_hubs = sorted(hub_scores.items(), key=lambda x: x[1], reverse=True)[:10]
                top_authorities = sorted(authority_scores.items(), key=lambda x: x[1], reverse=True)[:10]
                metrics["top_hubs"] = top_hubs
                metrics["top_authorities"] = top_authorities
        except Exception as e:
            logger.warning(f"שגיאה בחישוב מדדי גרף: {str(e)}")
        
        # חיפוש רכיבים קשירים חזק
        try:
            strongly_connected = list(nx.strongly_connected_components(graph))
            metrics["strongly_connected_components"] = [list(component) for component in strongly_connected]
        except Exception as e:
            logger.warning(f"שגיאה בחיפוש רכיבים קשירים חזק: {str(e)}")
        
        # חיפוש מעגלים (cycles)
        try:
            cycles = list(nx.simple_cycles(graph))
            metrics["cycles"] = [list(cycle) for cycle in cycles]
        except Exception as e:
            logger.warning(f"שגיאה בחיפוש מעגלים: {str(e)}")
        
        # המרת הגרף לפורמט JSON
        graph_data = {
            "nodes": [{"id": node, "name": data["name"]} for node, data in graph.nodes(data=True)],
            "edges": [{"source": source, "target": target} for source, target in graph.edges()]
        }
        
        logger.info(f"ניתוח קשרים הושלם: {len(graph.nodes())} קודקודים, {len(graph.edges())} קשתות")
        
        return {
            "graph": graph_data,
            "metrics": metrics
        }
    
    def calculate_project_statistics(self, file_paths: List[str]) -> Dict[str, Any]:
        """
        חישוב סטטיסטיקות לפרויקט
        
        Args:
            file_paths: רשימת נתיבים לקבצים לניתוח
            
        Returns:
            מילון עם סטטיסטיקות הפרויקט
        """
        logger.info(f"מחשב סטטיסטיקות עבור פרויקט עם {len(file_paths)} קבצים")
        
        # ניתוח כל הקבצים תחילה
        analysis_results = self.analyze_files(file_paths)
        
        # איסוף סטטיסטיקות בסיסיות
        total_files = len(file_paths)
        total_size_bytes = 0
        total_lines = 0
        total_code_lines = 0
        total_comment_lines = 0
        total_blank_lines = 0
        
        # התפלגות שפות
        languages = defaultdict(int)
        
        # סטטיסטיקות מורכבות קוד
        complexity_stats = {
            "cyclomatic_complexity": {
                "total": 0,
                "avg": 0,
                "max": 0,
                "file_with_max": ""
            },
            "nesting_depth": {
                "total": 0,
                "avg": 0,
                "max": 0,
                "file_with_max": ""
            }
        }
        
        # איסוף מידע
        for file_path, result in analysis_results["results"].items():
            if "error" in result or result.get("skipped", False):
                continue
            
            # גודל הקובץ
            if "size_bytes" in result:
                total_size_bytes += result["size_bytes"]
            elif "analysis" in result and "size_bytes" in result["analysis"]:
                total_size_bytes += result["analysis"]["size_bytes"]
            
            # שפת תכנות
            language = None
            if "language" in result:
                language = result["language"]
            elif "analysis" in result and "language" in result["analysis"]:
                language = result["analysis"]["language"]
            
            if language:
                languages[language] += 1
            
            # מספר שורות
            if "lines" in result:
                total_lines += result["lines"].get("total", 0)
                total_code_lines += result["lines"].get("code", 0)
                total_comment_lines += result["lines"].get("comments", 0)
                total_blank_lines += result["lines"].get("blank", 0)
            
            # מורכבות קוד
            if "complexity" in result:
                # מורכבות ציקלומטית
                if "cyclomatic" in result["complexity"]:
                    cyclomatic = result["complexity"]["cyclomatic"]
                    complexity_stats["cyclomatic_complexity"]["total"] += cyclomatic
                    if cyclomatic > complexity_stats["cyclomatic_complexity"]["max"]:
                        complexity_stats["cyclomatic_complexity"]["max"] = cyclomatic
                        complexity_stats["cyclomatic_complexity"]["file_with_max"] = file_path
                
                # עומק קינון
                if "max_nesting_depth" in result["complexity"]:
                    nesting = result["complexity"]["max_nesting_depth"]
                    complexity_stats["nesting_depth"]["total"] += nesting
                    if nesting > complexity_stats["nesting_depth"]["max"]:
                        complexity_stats["nesting_depth"]["max"] = nesting
                        complexity_stats["nesting_depth"]["file_with_max"] = file_path
        
        # חישוב ממוצעים
        non_skipped_files = total_files - analysis_results["summary"]["skipped_files"]
        
        if non_skipped_files > 0:
            complexity_stats["cyclomatic_complexity"]["avg"] = complexity_stats["cyclomatic_complexity"]["total"] / non_skipped_files
            complexity_stats["nesting_depth"]["avg"] = complexity_stats["nesting_depth"]["total"] / non_skipped_files
        
        # יצירת התפלגות שפות באחוזים
        language_percentage = {}
        for lang, count in languages.items():
            language_percentage[lang] = (count / non_skipped_files) * 100 if non_skipped_files > 0 else 0
        
        # ניתוח תלויות
        dependencies_stats = self._calculate_dependencies_stats(analysis_results["results"])
        
        # יצירת הסטטיסטיקה המלאה
        statistics = {
            "total_files": total_files,
            "total_size_bytes": total_size_bytes,
            "total_size_mb": total_size_bytes / (1024 * 1024),
            "lines": {
                "total": total_lines,
                "code": total_code_lines,
                "comments": total_comment_lines,
                "blank": total_blank_lines,
                "comment_ratio": (total_comment_lines / total_code_lines) * 100 if total_code_lines > 0 else 0
            },
            "languages": {
                "count": dict(languages),
                "percentage": language_percentage
            },
            "complexity": complexity_stats,
            "dependencies": dependencies_stats
        }
        
        logger.info(f"חישוב סטטיסטיקות הפרויקט הושלם")
        
        return statistics
    
    def _calculate_dependencies_stats(self, analysis_results: Dict[str, Any]) -> Dict[str, Any]:
        """
        חישוב סטטיסטיקות תלויות
        
        Args:
            analysis_results: תוצאות ניתוח הקבצים
            
        Returns:
            מילון עם סטטיסטיקות התלויות
        """
        # ספירת תלויות
        all_imports = []
        files_with_imports = 0
        unique_imports = set()
        
        # התפלגות תלויות לפי סוג ושפה
        import_types = defaultdict(int)
        imports_by_language = defaultdict(set)
        
        for result in analysis_results.values():
            if "error" in result or result.get("skipped", False):
                continue
            
            # איסוף ייבואים
            imports = []
            
            # תלויות ישירות מהניתוח
            if "imports" in result:
                imports.extend(result["imports"])
                files_with_imports += 1
            
            if imports:
                for imp in imports:
                    if isinstance(imp, dict):
                        all_imports.append(imp)
                        unique_imports.add(imp.get("source", ""))
                        
                        # ספירה לפי סוג
                        import_type = imp.get("type", "unknown")
                        import_types[import_type] += 1
                        
                        # הוספה לייבואים לפי שפה
                        language = result.get("language", "unknown")
                        if "source" in imp:
                            imports_by_language[language].add(imp["source"])
                    elif isinstance(imp, str):
                        all_imports.append(imp)
                        unique_imports.add(imp)
        
        # חישוב סטטיסטיקות
        stats = {
            "total_imports": len(all_imports),
            "unique_imports": len(unique_imports),
            "files_with_imports": files_with_imports,
            "avg_imports_per_file": len(all_imports) / files_with_imports if files_with_imports > 0 else 0,
            "import_types": dict(import_types),
            "imports_by_language": {lang: list(imps) for lang, imps in imports_by_language.items()}
        }
        
        return stats
    
    def _get_file_hash(self, file_path: str) -> str:
        """
        יצירת גיבוב (hash) של קובץ על סמך תוכנו והמטא-נתונים
        
        Args:
            file_path: נתיב לקובץ
            
        Returns:
            מחרוזת גיבוב
        """
        stats = os.stat(file_path)
        metadata = f"{file_path}_{stats.st_size}_{stats.st_mtime}"
        return hashlib.md5(metadata.encode()).hexdigest()
    
    def _detect_file_type(self, file_path: str) -> str:
        """
        זיהוי סוג הקובץ (בינארי או טקסט)
        
        Args:
            file_path: נתיב לקובץ
            
        Returns:
            סוג הקובץ ("text" או "binary")
        """
        # בדיקה אם הקובץ נמצא במטמון
        if file_path in self._file_types_cache:
            return self._file_types_cache[file_path]
        
        # בדיקת סיומת הקובץ
        extension = os.path.splitext(file_path)[1].lower()
        
        # סיומות של קבצי טקסט נפוצים
        text_extensions = {
            '.txt', '.py', '.js', '.html', '.htm', '.css', '.json', '.xml', '.md',
            '.yml', '.yaml', '.ini', '.cfg', '.conf', '.c', '.cpp', '.h', '.hpp',
            '.java', '.rb', '.php', '.go', '.rs', '.ts', '.tsx', '.jsx', '.kt',
            '.swift', '.scala', '.sh', '.bash', '.csv', '.log', '.sql', '.r'
        }
        
        # סיומות של קבצים בינאריים נפוצים
        binary_extensions = {
            '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.zip',
            '.tar', '.gz', '.rar', '.7z', '.exe', '.dll', '.so', '.o', '.obj',
            '.class', '.jar', '.pyc', '.pyo', '.pyd', '.png', '.jpg', '.jpeg',
            '.gif', '.bmp', '.tiff', '.ico', '.mp3', '.mp4', '.avi', '.mov',
            '.wmv', '.flv', '.wav', '.ogg', '.db', '.sqlite', '.mdb'
        }
        
        # בדיקה מהירה לפי סיומת
        if extension in text_extensions:
            self._file_types_cache[file_path] = "text"
            return "text"
        elif extension in binary_extensions:
            self._file_types_cache[file_path] = "binary"
            return "binary"
        
        # בדיקה מעמיקה יותר אם לא ניתן לקבוע לפי הסיומת
        try:
            with open(file_path, 'rb') as f:
                # קריאת 1024 בייטים ראשונים
                sample = f.read(1024)
                
                # בדיקה אם יש תווי null בקובץ (סימן לקובץ בינארי)
                if b'\0' in sample:
                    self._file_types_cache[file_path] = "binary"
                    return "binary"
                
                # בדיקה אם ניתן לפרש את הקובץ כטקסט
                try:
                    sample.decode('utf-8')
                    self._file_types_cache[file_path] = "text"
                    return "text"
                except UnicodeDecodeError:
                    try:
                        sample.decode('latin-1')
                        self._file_types_cache[file_path] = "text"
                        return "text"
                    except UnicodeDecodeError:
                        self._file_types_cache[file_path] = "binary"
                        return "binary"
                
        except Exception as e:
            logger.warning(f"שגיאה בזיהוי סוג הקובץ {file_path}: {str(e)}")
            # ברירת מחדל במקרה של שגיאה
            self._file_types_cache[file_path] = "binary"
            return "binary"
    
    def _detect_language(self, file_path: str) -> Optional[str]:
        """
        זיהוי שפת התכנות של הקובץ
        
        Args:
            file_path: נתיב לקובץ
            
        Returns:
            שם השפה או None אם לא זוהתה
        """
        # בדיקה לפי סיומת הקובץ
        extension = os.path.splitext(file_path)[1].lower()
        
        # בדיקה לפי דפוסי שפה
        for language, pattern in self.config["language_patterns"].items():
            if re.search(pattern, file_path, re.IGNORECASE):
                return language
        
        # אם לא זוהתה שפה לפי הסיומת, ננסה לזהות לפי תוכן
        if self._detect_file_type(file_path) == "text":
            try:
                # שימוש ב-pygments לזיהוי שפה לפי תוכן
                with open(file_path, 'rb') as f:
                    content = f.read(4096)  # מספיק לקרוא חלק מהקובץ
                    
                    try:
                        lexer = pygments.lexers.guess_lexer_for_filename(file_path, content)
                        return self._map_lexer_to_language(lexer.name)
                    except pygments.util.ClassNotFound:
                        try:
                            lexer = pygments.lexers.guess_lexer(content.decode('utf-8', errors='replace'))
                            return self._map_lexer_to_language(lexer.name)
                        except (pygments.util.ClassNotFound, UnicodeDecodeError):
                            pass
            except Exception as e:
                logger.debug(f"שגיאה בזיהוי שפה לפי תוכן {file_path}: {str(e)}")
        
        # אם לא הצלחנו לזהות את השפה
        return None
    
    def _map_lexer_to_language(self, lexer_name: str) -> str:
        """
        המרת שם לקסר pygments לשם שפה מובנה
        
        Args:
            lexer_name: שם הלקסר
            
        Returns:
            שם השפה
        """
        lexer_to_language = {
            "Python": "python",
            "JavaScript": "javascript",
            "TypeScript": "typescript",
            "Java": "java",
            "C": "c",
            "C++": "cpp",
            "C#": "csharp",
            "Go": "go",
            "Ruby": "ruby",
            "PHP": "php",
            "Rust": "rust",
            "HTML": "html",
            "CSS": "css",
            "Swift": "swift",
            "Kotlin": "kotlin",
            "Scala": "scala",
            "Bash": "shell",
            "Bourne Shell": "shell",
            "YAML": "yaml",
            "JSON": "json",
            "XML": "xml",
            "SQL": "sql",
            "Markdown": "markdown"
        }
        
        # חיפוש התאמה מדויקת
        if lexer_name in lexer_to_language:
            return lexer_to_language[lexer_name]
        
        # חיפוש התאמה חלקית
        for key, value in lexer_to_language.items():
            if key.lower() in lexer_name.lower():
                return value
        
        return "unknown"
    
    def _detect_encoding(self, file_path: str) -> str:
        """
        זיהוי קידוד הקובץ
        
        Args:
            file_path: נתיב לקובץ
            
        Returns:
            קידוד הקובץ
        """
        # קריאת מדגם מהקובץ
        try:
            with open(file_path, 'rb') as f:
                sample = f.read(4096)
            
            # זיהוי קידוד באמצעות chardet
            result = chardet.detect(sample)
            encoding = result['encoding']
            
            # אם הקידוד לא זוהה או אמינות נמוכה
            if not encoding or result['confidence'] < 0.7:
                encoding = self.config["default_encoding"]
                
            return encoding
            
        except Exception as e:
            logger.warning(f"שגיאה בזיהוי קידוד קובץ {file_path}: {str(e)}")
            return self.config["default_encoding"]
    
    def _analyze_by_language(self, file_path: str, content: str, language: str) -> Dict[str, Any]:
        """
        ניתוח מפורט של קובץ לפי שפת התכנות
        
        Args:
            file_path: נתיב הקובץ
            content: תוכן הקובץ
            language: שפת התכנות
            
        Returns:
            מילון עם תוצאות הניתוח
        """
        result = {
            "lines": self._count_lines(content)
        }
        
        # חילוץ ייבואים ותלויות
        imports = self._extract_imports(content, language)
        if imports:
            result["imports"] = imports
        
        # ניתוח מבנה הקוד לפי שפה
        if language == "python":
            structure = self._analyze_python_structure(content)
            if structure:
                result.update(structure)
        elif language in ["javascript", "typescript"]:
            structure = self._analyze_js_structure(content)
            if structure:
                result.update(structure)
        elif language == "java":
            structure = self._analyze_java_structure(content)
            if structure:
                result.update(structure)
        elif language in ["c", "cpp"]:
            structure = self._analyze_c_cpp_structure(content)
            if structure:
                result.update(structure)
        
        return result
    
    def _count_lines(self, content: str) -> Dict[str, int]:
        """
        ספירת שורות בקובץ: סה"כ, קוד, הערות, ריקות
        
        Args:
            content: תוכן הקובץ
            
        Returns:
            מילון עם מספרי השורות
        """
        lines = content.splitlines()
        total_lines = len(lines)
        blank_lines = sum(1 for line in lines if not line.strip())
        
        # ספירת הערות (הערכה גסה - לא מושלמת)
        comment_pattern = r'^\s*(#|//|/\*|\*|;|--)'
        comment_lines = sum(1 for line in lines if re.match(comment_pattern, line.strip()))
        
        # שורות קוד (שורות שאינן ריקות או הערות)
        code_lines = total_lines - blank_lines - comment_lines
        
        return {
            "total": total_lines,
            "code": code_lines,
            "comments": comment_lines,
            "blank": blank_lines
        }
    
    def _extract_imports(self, content: str, language: str) -> List[Dict[str, Any]]:
        """
        חילוץ ייבואים ותלויות מהקוד
        
        Args:
            content: תוכן הקובץ
            language: שפת התכנות
            
        Returns:
            רשימת ייבואים
        """
        imports = []
        
        # בדיקה אם יש דפוסי ייבוא מוגדרים לשפה זו
        if language in self.config["import_patterns"]:
            patterns = self.config["import_patterns"][language]
            
            for pattern, import_type in patterns:
                for match in re.finditer(pattern, content, re.MULTILINE):
                    # יש להתאים את האינדקס לפי הדפוס
                    if match.lastindex:
                        source = match.group(1)
                        imp = {
                            "source": source,
                            "type": import_type,
                            "line": content[:match.start()].count('\n') + 1
                        }
                        imports.append(imp)
        
        return imports
    
    def _analyze_python_structure(self, content: str) -> Dict[str, Any]:
        """
        ניתוח מבנה קוד Python
        
        Args:
            content: תוכן הקובץ
            
        Returns:
            מילון עם מבנה הקוד
        """
        result = {}
        
        try:
            # פרסור AST של Python
            tree = ast.parse(content)
            
            # רשימות לאחסון רכיבים
            classes = []
            functions = []
            variables = []
            
            # פרסור מחלקות ופונקציות
            for node in ast.walk(tree):
                if isinstance(node, ast.ClassDef):
                    methods = []
                    class_vars = []
                    
                    # איסוף מתודות ומשתני מחלקה
                    for item in node.body:
                        if isinstance(item, ast.FunctionDef):
                            methods.append({
                                "name": item.name,
                                "line": item.lineno,
                                "args": [arg.arg for arg in item.args.args],
                                "decorators": [d.id for d in item.decorator_list if isinstance(d, ast.Name)]
                            })
                        elif isinstance(item, ast.Assign):
                            for target in item.targets:
                                if isinstance(target, ast.Name):
                                    class_vars.append({
                                        "name": target.id,
                                        "line": item.lineno
                                    })
                    
                    classes.append({
                        "name": node.name,
                        "line": node.lineno,
                        "methods_count": len(methods),
                        "methods": methods,
                        "variables": class_vars,
                        "base_classes": [base.id if isinstance(base, ast.Name) else "complex_base" for base in node.bases],
                        "decorators": [d.id for d in node.decorator_list if isinstance(d, ast.Name)]
                    })
                    
                elif isinstance(node, ast.FunctionDef) and not any(isinstance(parent, ast.ClassDef) for parent in ast.iter_child_nodes(tree) if node in ast.iter_child_nodes(parent)):
                    functions.append({
                        "name": node.name,
                        "line": node.lineno,
                        "args": [arg.arg for arg in node.args.args],
                        "decorators": [d.id for d in node.decorator_list if isinstance(d, ast.Name)]
                    })
                    
                elif isinstance(node, ast.Assign) and all(isinstance(target, ast.Name) for target in node.targets):
                    for target in node.targets:
                        variables.append({
                            "name": target.id,
                            "line": node.lineno
                        })
            
            result["classes"] = classes
            result["functions"] = functions
            result["variables"] = variables
            result["syntax_valid"] = True
            
            # חילוץ פרטי מודול
            module_docstring = ast.get_docstring(tree)
            if module_docstring:
                result["module_docstring"] = module_docstring
            
            return result
            
        except SyntaxError as e:
            # במקרה של שגיאת תחביר
            logger.warning(f"שגיאת תחביר בקוד Python: {str(e)}")
            return {
                "syntax_valid": False,
                "syntax_error": {
                    "line": e.lineno,
                    "column": e.offset,
                    "message": str(e)
                }
            }
        except Exception as e:
            logger.warning(f"שגיאה בניתוח מבנה קוד Python: {str(e)}")
            return {}
    
    def _analyze_js_structure(self, content: str) -> Dict[str, Any]:
        """
        ניתוח מבנה קוד JavaScript/TypeScript
        
        Args:
            content: תוכן הקובץ
            
        Returns:
            מילון עם מבנה הקוד
        """
        # שימוש בביטויים רגולריים לניתוח בסיסי - לא מושלם אבל מספק מידע ראשוני
        result = {}
        
        # איתור מחלקות
        classes = []
        class_pattern = r'class\s+(\w+)(?:\s+extends\s+(\w+))?\s*{'
        for match in re.finditer(class_pattern, content):
            class_name = match.group(1)
            base_class = match.group(2) if match.group(2) else None
            line_num = content[:match.start()].count('\n') + 1
            
            # בדיקה אם זו מחלקה מיוצאת
            is_exported = bool(re.search(r'export\s+class\s+' + re.escape(class_name), content))
            
            classes.append({
                "name": class_name,
                "line": line_num,
                "base_class": base_class,
                "exported": is_exported
            })
        
        # איתור פונקציות
        functions = []
        function_patterns = [
            # רגילה
            r'function\s+(\w+)\s*\(([^)]*)\)',
            # ביטוי פונקציה
            r'(?:const|let|var)\s+(\w+)\s*=\s*function\s*\(([^)]*)\)',
            # פונקציית חץ
            r'(?:const|let|var)\s+(\w+)\s*=\s*\(([^)]*)\)\s*=>'
        ]
        
        for pattern in function_patterns:
            for match in re.finditer(pattern, content):
                func_name = match.group(1)
                params_str = match.group(2)
                line_num = content[:match.start()].count('\n') + 1
                
                # פרסור פרמטרים
                params = [p.strip() for p in params_str.split(',') if p.strip()]
                
                # בדיקה אם זו פונקציה מיוצאת
                is_exported = bool(re.search(r'export\s+(?:function|const|let|var)\s+' + re.escape(func_name), content))
                
                functions.append({
                    "name": func_name,
                    "line": line_num,
                    "params": params,
                    "exported": is_exported
                })
        
        # איתור ייבואים וייצואים
        imports = []
        import_patterns = [
            # ES6 imports
            r'import\s+{([^}]+)}\s+from\s+[\'"]([^\'"]+)[\'"]',
            r'import\s+(\w+)\s+from\s+[\'"]([^\'"]+)[\'"]',
            r'import\s+\*\s+as\s+(\w+)\s+from\s+[\'"]([^\'"]+)[\'"]',
            # CommonJS require
            r'(?:const|let|var)\s+(\w+)\s*=\s*require\([\'"]([^\'"]+)[\'"]\)'
        ]
        
        for pattern in import_patterns:
            for match in re.finditer(pattern, content):
                if ',' in match.group(1):
                    # מרובה ייבואים
                    imported_names = [name.strip() for name in match.group(1).split(',')]
                    source = match.group(2)
                    line_num = content[:match.start()].count('\n') + 1
                    
                    for name in imported_names:
                        imports.append({
                            "name": name,
                            "source": source,
                            "line": line_num,
                            "type": "es6"
                        })
                else:
                    # ייבוא בודד
                    name = match.group(1)
                    source = match.group(2)
                    line_num = content[:match.start()].count('\n') + 1
                    
                    imports.append({
                        "name": name,
                        "source": source,
                        "line": line_num,
                        "type": "es6" if "import" in content[match.start():match.start()+10] else "commonjs"
                    })
        
        # ייצוא
        exports = []
        export_patterns = [
            # ES6 exports
            r'export\s+(?:const|let|var|function|class)\s+(\w+)',
            r'export\s+default\s+(?:const|let|var|function|class)?\s*(\w+)',
            r'export\s+{\s*([^}]+)\s*}',
            # CommonJS exports
            r'module\.exports\s*=\s*(\w+)',
            r'exports\.(\w+)\s*='
        ]
        
        for pattern in export_patterns:
            for match in re.finditer(pattern, content):
                if ',' in match.group(1):
                    # מרובה ייצואים
                    exported_names = [name.strip() for name in match.group(1).split(',')]
                    line_num = content[:match.start()].count('\n') + 1
                    
                    for name in exported_names:
                        exports.append({
                            "name": name,
                            "line": line_num,
                            "type": "es6"
                        })
                else:
                    # ייצוא בודד
                    name = match.group(1)
                    line_num = content[:match.start()].count('\n') + 1
                    
                    is_default = bool(re.search(r'export\s+default', content[match.start():match.start()+20]))
                    
                    exports.append({
                        "name": name,
                        "line": line_num,
                        "type": "es6" if "export" in content[match.start():match.start()+10] else "commonjs",
                        "default": is_default
                    })
        
        # בדיקת React components
        react_components = []
        react_patterns = [
            # Class components
            r'class\s+(\w+)\s+extends\s+(?:React\.)?Component',
            # Functional components
            r'(?:function|const)\s+(\w+)\s*(?:\([^)]*\)|=\s*\([^)]*\))\s*(?:=>)?\s*{\s*(?:return\s*)?(?:<|\([\s\n]*<)'
        ]
        
        for pattern in react_patterns:
            for match in re.finditer(pattern, content):
                component_name = match.group(1)
                line_num = content[:match.start()].count('\n') + 1
                
                react_components.append({
                    "name": component_name,
                    "line": line_num,
                    "type": "class" if "class" in content[match.start():match.start()+10] else "functional"
                })
        
        # חיפוש async/await שימוש
        has_async = bool(re.search(r'async\s+function|async\s+\(|async\s+\w+\s*\(', content))
        has_await = bool(re.search(r'await\s+', content))
        
        # שמירת התוצאות
        result["classes"] = classes
        result["functions"] = functions
        result["imports"] = imports
        result["exports"] = exports
        
        if react_components:
            result["react_components"] = react_components
        
        if has_async or has_await:
            result["async_usage"] = {
                "has_async_functions": has_async,
                "has_await": has_await
            }
        
        return result
    
    def _analyze_java_structure(self, content: str) -> Dict[str, Any]:
        """
        ניתוח מבנה קוד Java
        
        Args:
            content: תוכן הקובץ
            
        Returns:
            מילון עם מבנה הקוד
        """
        result = {}
        
        # איתור חבילה
        package_match = re.search(r'package\s+([a-zA-Z0-9_.]+);', content)
        if package_match:
            result["package"] = package_match.group(1)
        
        # איתור ייבואים
        imports = []
        for match in re.finditer(r'import\s+(?:static\s+)?([a-zA-Z0-9_.]+(?:\.\*)?);', content):
            import_path = match.group(1)
            line_num = content[:match.start()].count('\n') + 1
            
            is_static = "static" in content[match.start():match.start()+20]
            is_wildcard = import_path.endswith(".*")
            
            imports.append({
                "path": import_path,
                "line": line_num,
                "static": is_static,
                "wildcard": is_wildcard
            })
        
        # איתור מחלקות
        classes = []
        class_pattern = r'(?:public|private|protected)?\s*(?:abstract|final)?\s*class\s+(\w+)(?:\s+extends\s+(\w+))?(?:\s+implements\s+([^{]+))?'
        for match in re.finditer(class_pattern, content):
            class_name = match.group(1)
            base_class = match.group(2)
            interfaces_str = match.group(3)
            line_num = content[:match.start()].count('\n') + 1
            
            # פרסור ממשקים
            interfaces = []
            if interfaces_str:
                interfaces = [i.strip() for i in interfaces_str.split(',')]
            
            # מאפייני מחלקה
            class_modifiers = []
            if "public" in content[match.start():match.start()+30]:
                class_modifiers.append("public")
            elif "private" in content[match.start():match.start()+30]:
                class_modifiers.append("private")
            elif "protected" in content[match.start():match.start()+30]:
                class_modifiers.append("protected")
            
            if "abstract" in content[match.start():match.start()+30]:
                class_modifiers.append("abstract")
            elif "final" in content[match.start():match.start()+30]:
                class_modifiers.append("final")
            
            classes.append({
                "name": class_name,
                "line": line_num,
                "modifiers": class_modifiers,
                "base_class": base_class,
                "interfaces": interfaces
            })
        
        # איתור ממשקים
        interfaces = []
        interface_pattern = r'(?:public|private|protected)?\s*interface\s+(\w+)(?:\s+extends\s+([^{]+))?'
        for match in re.finditer(interface_pattern, content):
            interface_name = match.group(1)
            extends_str = match.group(2)
            line_num = content[:match.start()].count('\n') + 1
            
            # פרסור ממשקי הורשה
            extends = []
            if extends_str:
                extends = [e.strip() for e in extends_str.split(',')]
            
            # מאפייני ממשק
            interface_modifiers = []
            if "public" in content[match.start():match.start()+30]:
                interface_modifiers.append("public")
            elif "private" in content[match.start():match.start()+30]:
                interface_modifiers.append("private")
            elif "protected" in content[match.start():match.start()+30]:
                interface_modifiers.append("protected")
            
            interfaces.append({
                "name": interface_name,
                "line": line_num,
                "modifiers": interface_modifiers,
                "extends": extends
            })
        
        # איתור מתודות
        methods = []
        method_pattern = r'(?:public|private|protected)?\s*(?:static|final|abstract|synchronized)?\s*(?:<[^>]+>\s*)?(?:[\w<>[\],\s]+)\s+(\w+)\s*\(([^)]*)\)'
        for match in re.finditer(method_pattern, content):
            method_name = match.group(1)
            params_str = match.group(2)
            line_num = content[:match.start()].count('\n') + 1
            
            # פרסור פרמטרים
            params = []
            if params_str.strip():
                param_parts = params_str.split(',')
                for param in param_parts:
                    param = param.strip()
                    if param:
                        param_match = re.search(r'(\w+(?:<[^>]+>)?(?:\[\])?)\s+(\w+)', param)
                        if param_match:
                            param_type = param_match.group(1)
                            param_name = param_match.group(2)
                            params.append({"type": param_type, "name": param_name})
            
            # מאפייני מתודה
            method_modifiers = []
            method_context = content[max(0, match.start()-50):match.start()+len(match.group(0))]
            
            if "public" in method_context:
                method_modifiers.append("public")
            elif "private" in method_context:
                method_modifiers.append("private")
            elif "protected" in method_context:
                method_modifiers.append("protected")
            
            if "static" in method_context:
                method_modifiers.append("static")
            if "final" in method_context:
                method_modifiers.append("final")
            if "abstract" in method_context:
                method_modifiers.append("abstract")
            if "synchronized" in method_context:
                method_modifiers.append("synchronized")
            
            # איתור טיפוס החזרה
            return_type_match = re.search(r'(?:public|private|protected)?\s*(?:static|final|abstract|synchronized)?\s*(?:<[^>]+>\s*)?(\w+(?:<[^>]+>)?(?:\[\])?)\s+' + re.escape(method_name), method_context)
            return_type = return_type_match.group(1) if return_type_match else "unknown"
            
            methods.append({
                "name": method_name,
                "line": line_num,
                "modifiers": method_modifiers,
                "params": params,
                "return_type": return_type
            })
        
        # שמירת התוצאות
        result["imports"] = imports
        result["classes"] = classes
        result["interfaces"] = interfaces
        result["methods"] = methods
        
        return result
    
    def _analyze_c_cpp_structure(self, content: str) -> Dict[str, Any]:
        """
        ניתוח מבנה קוד C/C++
        
        Args:
            content: תוכן הקובץ
            
        Returns:
            מילון עם מבנה הקוד
        """
        result = {}
        
        # איתור include
        includes = []
        for match in re.finditer(r'#include\s*[<"]([^>"]+)[>"]', content):
            include_path = match.group(1)
            line_num = content[:match.start()].count('\n') + 1
            
            is_system = '<' in content[match.start():match.start()+20]
            
            includes.append({
                "path": include_path,
                "line": line_num,
                "system": is_system
            })
        
        # איתור define
        defines = []
        for match in re.finditer(r'#define\s+(\w+)(?:\s+(.+))?', content):
            define_name = match.group(1)
            define_value = match.group(2)
            line_num = content[:match.start()].count('\n') + 1
            
            defines.append({
                "name": define_name,
                "value": define_value.strip() if define_value else None,
                "line": line_num
            })
        
        # איתור מבני struct
        structs = []
        struct_pattern = r'(?:typedef\s+)?struct\s+(?:(\w+)\s*{|{[^}]*}\s*(\w+))'
        for match in re.finditer(struct_pattern, content):
            struct_name = match.group(1) or match.group(2)
            line_num = content[:match.start()].count('\n') + 1
            
            structs.append({
                "name": struct_name,
                "line": line_num,
                "typedef": "typedef" in content[max(0, match.start()-20):match.start()+10]
            })
        
        # איתור מחלקות (C++)
        classes = []
        class_pattern = r'(?:class|struct)\s+(\w+)(?:\s*:\s*(?:public|protected|private)?\s*(\w+))?'
        for match in re.finditer(class_pattern, content):
            class_name = match.group(1)
            base_class = match.group(2)
            line_num = content[:match.start()].count('\n') + 1
            
            is_struct = "struct" in content[match.start():match.start()+10]
            
            classes.append({
                "name": class_name,
                "line": line_num,
                "type": "struct" if is_struct else "class",
                "base_class": base_class
            })
        
        # איתור פונקציות
        functions = []
        function_pattern = r'(?:static|inline|extern)?\s*(?:[\w:*&]+\s+)+(\w+)\s*\(([^)]*)\)'
        for match in re.finditer(function_pattern, content):
            func_name = match.group(1)
            params_str = match.group(2)
            line_num = content[:match.start()].count('\n') + 1
            
            # פרסור פרמטרים
            params = []
            if params_str.strip() and params_str.strip() != "void":
                param_parts = params_str.split(',')
                for param in param_parts:
                    param = param.strip()
                    if param:
                        # ניסיון לזהות את השם והטיפוס
                        param_match = re.search(r'([\w:*&]+(?:\s+[\w:*&]+)*)\s+(\w+)(?:\[\])?$', param)
                        if param_match:
                            param_type = param_match.group(1)
                            param_name = param_match.group(2)
                            params.append({"type": param_type, "name": param_name})
                        else:
                            # אם לא הצלחנו להפריד את השם והטיפוס
                            params.append({"type": param, "name": ""})
            
            # מאפייני פונקציה
            function_modifiers = []
            function_context = content[max(0, match.start()-50):match.start()+len(match.group(0))]
            
            if "static" in function_context:
                function_modifiers.append("static")
            if "inline" in function_context:
                function_modifiers.append("inline")
            if "extern" in function_context:
                function_modifiers.append("extern")
            
            # איתור טיפוס החזרה
            return_type_match = re.search(r'([\w:*&]+(?:\s+[\w:*&]+)*)\s+' + re.escape(func_name) + r'\s*\(', function_context)
            return_type = return_type_match.group(1).strip() if return_type_match else "unknown"
            
            functions.append({
                "name": func_name,
                "line": line_num,
                "modifiers": function_modifiers,
                "params": params,
                "return_type": return_type
            })
        
        # איתור namespace (C++)
        namespaces = []
        for match in re.finditer(r'namespace\s+(\w+)', content):
            namespace_name = match.group(1)
            line_num = content[:match.start()].count('\n') + 1
            
            namespaces.append({
                "name": namespace_name,
                "line": line_num
            })
        
        # איתור typedef
        typedefs = []
        for match in re.finditer(r'typedef\s+([^;{]+)\s+(\w+);', content):
            original_type = match.group(1).strip()
            new_type = match.group(2)
            line_num = content[:match.start()].count('\n') + 1
            
            typedefs.append({
                "original_type": original_type,
                "new_type": new_type,
                "line": line_num
            })
        
        # שמירת התוצאות
        result["includes"] = includes
        result["defines"] = defines
        result["structs"] = structs
        
        # תוספות C++
        if classes:
            result["classes"] = classes
        if namespaces:
            result["namespaces"] = namespaces
        
        result["functions"] = functions
        result["typedefs"] = typedefs
        
        return result
    
    def _detect_license(self, content: str) -> Optional[Dict[str, Any]]:
        """
        זיהוי רישיון בקוד
        
        Args:
            content: תוכן הקובץ
            
        Returns:
            מילון עם פרטי הרישיון או None אם לא זוהה
        """
        # זיהוי רישיונות נפוצים
        license_patterns = [
            (r'MIT License', "MIT"),
            (r'Apache License', "Apache"),
            (r'GNU General Public License', "GPL"),
            (r'GNU Lesser General Public License', "LGPL"),
            (r'BSD [0-9]-Clause License', "BSD"),
            (r'Mozilla Public License', "MPL"),
            (r'Copyright \(c\)', "Proprietary"),
            (r'This Source Code Form is subject to the terms of the Mozilla Public License', "MPL"),
            (r'http://www.apache.org/licenses/LICENSE-2.0', "Apache-2.0"),
            (r'http://opensource.org/licenses/MIT', "MIT"),
            (r'http://www.gnu.org/licenses/', "GPL")
        ]
        
        # חיפוש בתוכן
        for pattern, license_type in license_patterns:
            match = re.search(pattern, content)
            if match:
                # מיקום במסמך
                line_num = content[:match.start()].count('\n') + 1
                
                # חיפוש שנת זכויות יוצרים
                copyright_year_match = re.search(r'Copyright (?:\(c\))?\s*(?:[©Ⓒ])?\s*([0-9]{4}(?:\s*-\s*[0-9]{4})?)', content)
                copyright_year = copyright_year_match.group(1) if copyright_year_match else None
                
                # חיפוש שם המחבר/בעלים
                copyright_owner_match = re.search(r'Copyright (?:\(c\))?\s*(?:[©Ⓒ])?\s*(?:[0-9]{4}(?:\s*-\s*[0-9]{4})?)?\s*(?:by)?\s*(.+?)(?:\.|$)', content)
                copyright_owner = copyright_owner_match.group(1).strip() if copyright_owner_match else None
                
                return {
                    "type": license_type,
                    "line": line_num,
                    "copyright_year": copyright_year,
                    "copyright_owner": copyright_owner
                }
        
        return None
    
    def _calculate_complexity_metrics(self, content: str, language: str) -> Dict[str, Any]:
        """
        חישוב מדדי מורכבות קוד
        
        Args:
            content: תוכן הקובץ
            language: שפת התכנות
            
        Returns:
            מילון עם מדדי המורכבות
        """
        metrics = {}
        
        # חישוב מורכבות ציקלומטית
        if language == "python":
            metrics["cyclomatic"] = self._calculate_python_cyclomatic_complexity(content)
        else:
            # הערכה גסה למורכבות ציקלומטית - ספירת מבני שליטה
            control_patterns = [
                r'\bif\b', r'\belse\b', r'\bfor\b', r'\bwhile\b', r'\bcase\b',
                r'\bcatch\b', r'\?', r'\|\|', r'\&\&'
            ]
            
            # ספירת הופעות
            complexity = 1  # ערך בסיסי
            for pattern in control_patterns:
                complexity += len(re.findall(pattern, content))
            
            metrics["cyclomatic"] = complexity
        
        # חישוב עומק קינון מקסימלי
        max_nesting = self._calculate_max_nesting_depth(content)
        metrics["max_nesting_depth"] = max_nesting
        
        # חישוב מורכבות הלבאן (מספר אופרטורים ואופרנדים ייחודיים)
        halstead_metrics = self._calculate_halstead_complexity(content, language)
        if halstead_metrics:
            metrics["halstead"] = halstead_metrics
        
        # הערכת מורכבות לפי אורך הקוד
        lines_count = content.count('\n') + 1
        if lines_count < 100:
            metrics["size_complexity"] = "low"
        elif lines_count < 500:
            metrics["size_complexity"] = "medium"
        else:
            metrics["size_complexity"] = "high"
        
        # הערכת תחזוקתיות
        if "cyclomatic" in metrics and "max_nesting_depth" in metrics:
            maintainability = self._calculate_maintainability_index(
                metrics["cyclomatic"],
                lines_count,
                metrics["max_nesting_depth"]
            )
            metrics["maintainability_index"] = maintainability
        
        return metrics
    
    def _calculate_python_cyclomatic_complexity(self, content: str) -> int:
        """
        חישוב מורכבות ציקלומטית לקוד Python
        
        Args:
            content: תוכן הקובץ
            
        Returns:
            מספר המורכבות הציקלומטית
        """
        try:
            # פרסור AST של הקוד
            tree = ast.parse(content)
            
            # ספירת מבני שליטה
            complexity = 1  # ערך בסיסי
            
            for node in ast.walk(tree):
                # מבני תנאי
                if isinstance(node, (ast.If, ast.IfExp)):
                    complexity += 1
                # לולאות
                elif isinstance(node, (ast.For, ast.While, ast.AsyncFor)):
                    complexity += 1
                # טיפול בשגיאות
                elif isinstance(node, ast.ExceptHandler):
                    complexity += 1
                # מפעילים בוליאניים
                elif isinstance(node, ast.BoolOp):
                    complexity += len(node.values) - 1
                # comprehensions
                elif isinstance(node, ast.comprehension):
                    complexity += len(node.ifs)
            
            return complexity
            
        except SyntaxError:
            # במקרה של שגיאת תחביר, נחזיר ערך ברירת מחדל
            return 1
        except Exception as e:
            logger.warning(f"שגיאה בחישוב מורכבות ציקלומטית: {str(e)}")
            return 1
    
    def _calculate_max_nesting_depth(self, content: str) -> int:
        """
        חישוב עומק קינון מקסימלי
        
        Args:
            content: תוכן הקובץ
            
        Returns:
            עומק הקינון המקסימלי
        """
        lines = content.splitlines()
        max_depth = 0
        current_depth = 0
        
        # איתור שורות מקוננות לפי הזחות
        for line in lines:
            # דילוג על שורות ריקות והערות
            if not line.strip() or line.strip().startswith(('#', '//', '/*', '*')):
                continue
            
            # זיהוי רמת קינון לפי הזחה (לא מושלם אבל עובד כהערכה)
            indent_level = len(line) - len(line.lstrip())
            
            # במקום לחשב הזחה מדויקת, נשתמש בשינויים בהזחה לזיהוי רמות קינון
            if current_depth == 0:
                # קו ראשון עם תוכן
                current_depth = 1
            elif indent_level > 0:
                # חישוב קינון בהתאם לרמת ההזחה
                estimated_depth = (indent_level // 2) + 1
                current_depth = estimated_depth
            
            # עדכון עומק קינון מקסימלי
            max_depth = max(max_depth, current_depth)
        
        return max_depth
    
    def _calculate_halstead_complexity(self, content: str, language: str) -> Optional[Dict[str, Any]]:
        """
        חישוב מורכבות הלבאן
        
        Args:
            content: תוכן הקובץ
            language: שפת התכנות
            
        Returns:
            מילון עם מדדי הלבאן
        """
        # הגדרת אופרטורים לפי שפה
        operators_by_language = {
            "python": [
                '+', '-', '*', '/', '//', '%', '**', '==', '!=', '>', '<', '>=', '<=',
                'and', 'or', 'not', 'is', 'in', 'not in', 'is not'
            ],
            "javascript": [
                '+', '-', '*', '/', '%', '**', '==', '===', '!=', '!==', '>', '<', '>=', '<=',
                '&&', '||', '!', 'typeof', 'instanceof', '?', ':'
            ],
            "java": [
                '+', '-', '*', '/', '%', '==', '!=', '>', '<', '>=', '<=',
                '&&', '||', '!', 'instanceof', '?', ':', '&', '|', '^', '~', '<<', '>>', '>>>'
            ],
            "c": [
                '+', '-', '*', '/', '%', '==', '!=', '>', '<', '>=', '<=',
                '&&', '||', '!', '&', '|', '^', '~', '<<', '>>'
            ],
            "cpp": [
                '+', '-', '*', '/', '%', '==', '!=', '>', '<', '>=', '<=',
                '&&', '||', '!', '&', '|', '^', '~', '<<', '>>', '::'
            ]
        }
        
        # אם אין הגדרת אופרטורים לשפה, לא נחשב
        if language not in operators_by_language:
            return None
        
        operators = operators_by_language[language]
        
        # מניית אופרטורים
        operators_count = 0
        unique_operators = set()
        
        for op in operators:
            count = len(re.findall(r'\b' + re.escape(op) + r'\b' if len(op) > 1 else re.escape(op), content))
            operators_count += count
            if count > 0:
                unique_operators.add(op)
        
        # חישוב אופרנדים באופן גס
        # נמנה מזהים (משתנים, פונקציות) ומספרים כאופרנדים
        operands_pattern = r'\b[a-zA-Z_]\w*\b|\b\d+\b'
        all_operands = re.findall(operands_pattern, content)
        operands_count = len(all_operands)
        unique_operands = set(all_operands)
        
        # אם אין מספיק מידע, לא נחשב
        if not unique_operators or not unique_operands:
            return None
        
        # חישוב מדדי הלבאן
        n1 = len(unique_operators)
        n2 = len(unique_operands)
        N1 = operators_count
        N2 = operands_count
        
        # מדדים בסיסיים
        vocabulary = n1 + n2
        length = N1 + N2
        
        # מדדים מחושבים
        volume = length * (math.log2(vocabulary) if vocabulary > 0 else 0)
        difficulty = (n1 / 2) * (N2 / n2) if n2 > 0 else 0
        effort = volume * difficulty
        
        return {
            "unique_operators": n1,
            "unique_operands": n2,
            "total_operators": N1,
            "total_operands": N2,
            "vocabulary": vocabulary,
            "length": length,
            "volume": volume,
            "difficulty": difficulty,
            "effort": effort
        }
    
    def _calculate_maintainability_index(self, cyclomatic: int, lines: int, nesting: int) -> float:
        """
        חישוב מדד תחזוקתיות
        
        Args:
            cyclomatic: מורכבות ציקלומטית
            lines: מספר שורות
            nesting: עומק קינון
            
        Returns:
            מדד תחזוקתיות
        """
        # נוסחה פשוטה לחישוב מדד תחזוקתיות
        # ערכים גבוהים יותר מעידים על תחזוקתיות טובה יותר (0-100)
        import math
        
        # מקדמים משוקללים
        weight_cc = 0.25  # משקל למורכבות ציקלומטית
        weight_loc = 0.05  # משקל למספר שורות
        weight_nest = 0.2  # משקל לעומק קינון
        
        # חישוב לוגריתמי כדי לקחת בחשבון גדילה לא לינארית של מורכבות
        cc_factor = weight_cc * cyclomatic
        loc_factor = weight_loc * math.log(max(1, lines))
        nest_factor = weight_nest * nesting
        
        # חישוב המדד
        raw_mi = 100 - (cc_factor + loc_factor + nest_factor) * 10
        
        # הגבלת התוצאה לטווח 0-100
        maintainability = max(0, min(100, raw_mi))
        
        return round(maintainability, 2)
    
    def _find_matching_files(self, dependency: str, file_paths: List[str], source_file: str) -> List[str]:
        """
        איתור קבצים התואמים לתלות
        
        Args:
            dependency: שם התלות
            file_paths: רשימת נתיבי קבצים
            source_file: קובץ המקור
            
        Returns:
            רשימת נתיבי קבצים תואמים
        """
        # התאמות מצויות
        matches = []
        
        # טיפול במקרה של נתיב יחסי
        source_dir = os.path.dirname(source_file)
        
        # ניסיון להתאים לקבצים קיימים
        for file_path in file_paths:
            file_name = os.path.basename(file_path)
            file_name_no_ext = os.path.splitext(file_name)[0]
            
            # התאמה מדויקת
            if file_name_no_ext == dependency:
                matches.append(file_path)
                continue
            
            # התאמה חלקית - השוואת סוף נתיב
            dependency_parts = dependency.split('.')
            file_path_parts = file_path.split(os.path.sep)
            
            # בדיקה אם סוף הנתיב תואם
            if len(dependency_parts) <= len(file_path_parts):
                matching = True
                for i in range(1, len(dependency_parts) + 1):
                    dep_part = dependency_parts[-i]
                    file_part = os.path.splitext(file_path_parts[-i])[0]
                    
                    if dep_part != file_part:
                        matching = False
                        break
                
                if matching:
                    matches.append(file_path)
                    continue
            
            # בדיקת נתיב יחסי (לדוגמה: './module' או '../utils')
            if dependency.startswith('.'):
                # נרמול הנתיב היחסי
                rel_dependency = dependency.lstrip('.')
                
                # בניית נתיב אפשרי
                levels_up = dependency.count('.') - (1 if dependency.startswith('.') else 0)
                target_dir = source_dir
                
                for _ in range(levels_up):
                    target_dir = os.path.dirname(target_dir)
                
                potential_path = os.path.join(target_dir, rel_dependency.replace('.', os.path.sep))
                
                # בדיקה אם הקובץ התואם נמצא ברשימה
                for candidate in file_paths:
                    if candidate.startswith(potential_path):
                        matches.append(candidate)
        
        return matches

# ייבוא ספריות מתמטיות לחישובים
import math
