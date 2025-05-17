#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
מודול ראשי עבור מאחד קוד חכם Pro 2.0
מנהל את הפונקציונליות הכוללת של המערכת

מחבר: Claude AI
גרסה: 2.0.0
תאריך: מאי 2025
"""

import os
import sys
import json
import logging
import argparse
import tempfile
from typing import Dict, List, Tuple, Any, Optional, Union
from pathlib import Path

# ייבוא מודולי ליבה
from core.file_analyzer import FileAnalyzer
from core.relationship_graph import RelationshipGraph

# הגדרת נתיב לוג
LOG_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'logs')
os.makedirs(LOG_DIR, exist_ok=True)
LOG_FILE = os.path.join(LOG_DIR, 'smart_code_merger.log')

# הגדרת לוגר
logger = logging.getLogger('smart_code_merger')
logger.setLevel(logging.INFO)

# הגדרת מטפל קובץ
file_handler = logging.FileHandler(LOG_FILE, encoding='utf-8')
file_handler.setLevel(logging.INFO)

# הגדרת מטפל קונסולה
console_handler = logging.StreamHandler()
console_handler.setLevel(logging.INFO)

# הגדרת פורמט
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
file_handler.setFormatter(formatter)
console_handler.setFormatter(formatter)

# הוספת מטפלים ללוגר
logger.addHandler(file_handler)
logger.addHandler(console_handler)

class SmartCodeMerger:
    """
    מנהל איחוד קוד חכם
    מערכת מרכזית לניתוח, זיהוי ומיזוג של קבצי קוד
    """
    
    def __init__(self, config_path: Optional[str] = None):
        """
        אתחול מנהל מיזוג קוד חכם
        
        Args:
            config_path: נתיב לקובץ קונפיגורציה (אופציונלי)
        """
        logger.info("מאתחל מאחד קוד חכם Pro 2.0")
        
        # טעינת קונפיגורציה
        self.config = self._load_config(config_path)
        logger.debug(f"טעינת קונפיגורציה: {len(self.config)} פרמטרים")
        
        # אתחול מודולי ליבה
        self.file_analyzer = FileAnalyzer(self.config.get('file_analyzer', {}))
        self.relationship_graph = RelationshipGraph(self.config.get('relationship_graph', {}))
        
        # הגדרת מבני נתונים פנימיים
        self.analyzed_files = {}
        self.relationships = {}
        self.current_project = None
        
        logger.info("מאחד קוד חכם אותחל בהצלחה")
    
    def _load_config(self, config_path: Optional[str] = None) -> Dict[str, Any]:
        """
        טעינת הגדרות קונפיגורציה
        
        Args:
            config_path: נתיב לקובץ קונפיגורציה
            
        Returns:
            מילון קונפיגורציה
        """
        # הגדרות ברירת מחדל
        default_config = {
            "file_analyzer": {
                "max_file_size_mb": 100,
                "skip_binary_files": True,
                "parallel_processing": True,
                "max_workers": os.cpu_count() or 4,
                "encoding_detection": True,
                "default_encoding": "utf-8",
                "detect_license": True,
                "detailed_analysis": True
            },
            "relationship_graph": {
                "include_snippets": True,
                "max_nodes": 500,
                "min_edge_weight": 1,
                "layout_algorithm": "force_directed",
                "color_scheme": "category",
                "detect_communities": True
            },
            "merge": {
                "default_strategy": "smart",
                "resolve_conflicts": True,
                "include_comments": True,
                "backup_files": True,
                "line_ending": "auto"
            },
            "security": {
                "scan_dependencies": True,
                "check_secrets": True,
                "check_licenses": True,
                "vulnerability_db_update": "auto",
                "min_severity": "medium"
            },
            "general": {
                "temp_dir": tempfile.gettempdir(),
                "log_level": "info",
                "ui_language": "he",
                "ui_theme": "light",
                "auto_save": True
            }
        }
        
        # אם לא הוגדר נתיב, נחפש בנתיב ברירת מחדל
        if config_path is None:
            default_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'config.json')
            if os.path.exists(default_path):
                config_path = default_path
        
        # אם קיים קובץ קונפיגורציה, טען אותו
        if config_path and os.path.exists(config_path):
            try:
                with open(config_path, 'r', encoding='utf-8') as f:
                    user_config = json.load(f)
                    
                # מיזוג קונפיגורציה
                config = self._merge_config(default_config, user_config)
                logger.info(f"נטען קובץ קונפיגורציה: {config_path}")
                return config
            except Exception as e:
                logger.error(f"שגיאה בטעינת קובץ קונפיגורציה: {str(e)}")
        
        # אם אין קובץ, השתמש בהגדרות ברירת מחדל
        logger.info("משתמש בהגדרות ברירת מחדל")
        return default_config
    
    def _merge_config(self, target: Dict[str, Any], source: Dict[str, Any]) -> Dict[str, Any]:
        """
        מיזוג רקורסיבי של מילוני קונפיגורציה
        
        Args:
            target: מילון היעד
            source: מילון המקור לשילוב
            
        Returns:
            מילון ממוזג
        """
        result = target.copy()
        
        for key, value in source.items():
            if key in result and isinstance(result[key], dict) and isinstance(value, dict):
                # מיזוג רקורסיבי של תת-מילונים
                result[key] = self._merge_config(result[key], value)
            else:
                # החלפת ערך או הוספת מפתח חדש
                result[key] = value
        
        return result
    
    def analyze_file(self, file_path: str) -> Dict[str, Any]:
        """
        ניתוח של קובץ בודד
        
        Args:
            file_path: נתיב לקובץ לניתוח
            
        Returns:
            תוצאות הניתוח
        """
        logger.info(f"מנתח קובץ: {file_path}")
        
        try:
            # ניתוח הקובץ באמצעות FileAnalyzer
            result = self.file_analyzer.analyze_file(file_path)
            
            # שמירת התוצאות בזיכרון
            self.analyzed_files[file_path] = result
            
            logger.info(f"ניתוח קובץ הושלם: {file_path}")
            return result
        except Exception as e:
            logger.error(f"שגיאה בניתוח קובץ {file_path}: {str(e)}")
            return {"error": str(e), "path": file_path}
    
    def analyze_project(self, project_path: str, include_subfolders: bool = True, file_extensions: Optional[List[str]] = None) -> Dict[str, Any]:
        """
        ניתוח של פרויקט שלם
        
        Args:
            project_path: נתיב לתיקיית הפרויקט
            include_subfolders: האם לכלול תתי-תיקיות
            file_extensions: רשימת סיומות קבצים לניתוח
            
        Returns:
            תוצאות הניתוח
        """
        logger.info(f"מנתח פרויקט: {project_path}")
        
        # אם לא הוגדרו סיומות, השתמש ברשימת ברירת מחדל
        if file_extensions is None:
            file_extensions = ['.py', '.js', '.ts', '.java', '.c', '.cpp', '.h', '.hpp', '.cs', '.go', '.rb', '.php', '.html', '.css']
        
        # איסוף רשימת קבצים לניתוח
        file_paths = []
        
        if include_subfolders:
            # עבור על כל הקבצים בתיקייה ובתתי-תיקיות
            for root, _, files in os.walk(project_path):
                for file in files:
                    file_path = os.path.join(root, file)
                    # בדוק אם הסיומת נמצאת ברשימה (או אם הרשימה ריקה)
                    if not file_extensions or any(file.endswith(ext) for ext in file_extensions):
                        file_paths.append(file_path)
        else:
            # רק קבצים בתיקייה הראשית
            for file in os.listdir(project_path):
                file_path = os.path.join(project_path, file)
                if os.path.isfile(file_path):
                    # בדוק אם הסיומת נמצאת ברשימה (או אם הרשימה ריקה)
                    if not file_extensions or any(file.endswith(ext) for ext in file_extensions):
                        file_paths.append(file_path)
        
        # ניתוח כל הקבצים
        if file_paths:
            logger.info(f"נמצאו {len(file_paths)} קבצים לניתוח")
            
            # ניתוח קבצים
            analysis_results = self.file_analyzer.analyze_files(file_paths)
            
            # ניתוח קשרים
            self.relationships = self.file_analyzer.analyze_relationships(file_paths)
            
            # בניית גרף קשרים
            self.relationship_graph.build_graph_from_analysis(analysis_results)
            
            # חישוב סטטיסטיקות פרויקט
            project_stats = self.file_analyzer.calculate_project_statistics(file_paths)
            
            # עדכון הפרויקט הנוכחי
            self.current_project = {
                "path": project_path,
                "files": file_paths,
                "analysis": analysis_results,
                "relationships": self.relationships,
                "statistics": project_stats
            }
            
            logger.info(f"ניתוח פרויקט הושלם: {project_path}")
            return self.current_project
        else:
            logger.warning(f"לא נמצאו קבצים לניתוח בנתיב: {project_path}")
            return {"error": "no_files_found", "path": project_path}
    
    def analyze_relationships(self, file_paths: List[str]) -> Dict[str, Any]:
        """
        ניתוח קשרים בין קבצים
        
        Args:
            file_paths: רשימת נתיבים לקבצים לניתוח
            
        Returns:
            תוצאות ניתוח הקשרים
        """
        logger.info(f"מנתח קשרים בין {len(file_paths)} קבצים")
        
        try:
            # ניתוח קבצים אם עדיין לא נותחו
            for file_path in file_paths:
                if file_path not in self.analyzed_files:
                    self.analyze_file(file_path)
            
            # ניתוח קשרים
            relationships = self.file_analyzer.analyze_relationships(file_paths)
            
            # בניית גרף קשרים
            self.relationship_graph.build_graph_from_analysis({"results": {fp: self.analyzed_files[fp] for fp in file_paths}})
            
            # שמירת היחסים
            self.relationships = relationships
            
            logger.info(f"ניתוח קשרים הושלם")
            return relationships
        except Exception as e:
            logger.error(f"שגיאה בניתוח קשרים: {str(e)}")
            return {"error": str(e)}
    
    def visualize_relationships(self, output_format: str = "html", output_path: Optional[str] = None) -> Optional[str]:
        """
        יצירת ויזואליזציה של גרף הקשרים
        
        Args:
            output_format: פורמט הקובץ ("png", "svg", "pdf", "html")
            output_path: נתיב לשמירת הקובץ
            
        Returns:
            נתיב הקובץ שנוצר או None במקרה של שגיאה
        """
        logger.info(f"יוצר ויזואליזציה בפורמט {output_format}")
        
        try:
            if output_format.lower() == "html":
                # יצירת ויזואליזציה אינטראקטיבית
                html_content = self.relationship_graph.get_html_visualization()
                
                if output_path is None:
                    output_path = os.path.join(tempfile.gettempdir(), "relationships.html")
                
                with open(output_path, 'w', encoding='utf-8') as f:
                    f.write(html_content)
            else:
                # יצירת ויזואליזציה סטטית
                output_path = self.relationship_graph.visualize(output_format, output_path)
            
            logger.info(f"ויזואליזציה נוצרה: {output_path}")
            return output_path
        except Exception as e:
            logger.error(f"שגיאה ביצירת ויזואליזציה: {str(e)}")
            return None
    
    def export_graph(self, format: str, output_path: Optional[str] = None) -> Optional[str]:
        """
        ייצוא גרף הקשרים לפורמט מבוקש
        
        Args:
            format: פורמט הייצוא ("json", "graphml", "dot", "gexf")
            output_path: נתיב קובץ היעד
            
        Returns:
            נתיב הקובץ שנוצר או None במקרה של שגיאה
        """
        logger.info(f"מייצא גרף בפורמט {format}")
        
        try:
            output_path = self.relationship_graph.export_graph(format, output_path)
            
            if output_path:
                logger.info(f"גרף יוצא בהצלחה: {output_path}")
                return output_path
            else:
                logger.error("ייצוא הגרף נכשל")
                return None
        except Exception as e:
            logger.error(f"שגיאה בייצוא גרף: {str(e)}")
            return None
    
    def find_cyclic_dependencies(self) -> List[List[str]]:
        """
        איתור תלויות מעגליות בפרויקט
        
        Returns:
            רשימת מעגלי תלויות
        """
        logger.info("מחפש תלויות מעגליות")
        
        try:
            cycles = self.relationship_graph.find_cyclic_dependencies()
            
            if cycles:
                logger.info(f"נמצאו {len(cycles)} תלויות מעגליות")
            else:
                logger.info("לא נמצאו תלויות מעגליות")
                
            return cycles
        except Exception as e:
            logger.error(f"שגיאה בחיפוש תלויות מעגליות: {str(e)}")
            return []
    
    def analyze_dependencies(self) -> Dict[str, Any]:
        """
        ניתוח מקיף של תלויות בפרויקט
        
        Returns:
            מילון עם ניתוח התלויות
        """
        logger.info("מנתח תלויות")
        
        try:
            dependency_analysis = self.relationship_graph.analyze_dependencies()
            
            logger.info("ניתוח תלויות הושלם")
            return dependency_analysis
        except Exception as e:
            logger.error(f"שגיאה בניתוח תלויות: {str(e)}")
            return {"error": str(e)}
    
    def merge_files(self, file1_path: str, file2_path: str, output_path: str, strategy: str = "smart") -> Dict[str, Any]:
        """
        מיזוג של שני קבצי קוד
        
        Args:
            file1_path: נתיב לקובץ ראשון
            file2_path: נתיב לקובץ שני
            output_path: נתיב לקובץ התוצאה
            strategy: אסטרטגיית מיזוג ("smart", "keep-left", "keep-right", "both")
            
        Returns:
            תוצאות המיזוג
        """
        logger.info(f"ממזג קבצים: {file1_path} + {file2_path} -> {output_path}")
        logger.info(f"אסטרטגיית מיזוג: {strategy}")
        
        # TODO: להשלים לאחר פיתוח מודול merger
        
        return {
            "success": True,
            "file1": file1_path,
            "file2": file2_path,
            "output": output_path,
            "strategy": strategy,
            "changes": {
                "added": 0,
                "removed": 0,
                "modified": 0,
                "conflicts_resolved": 0
            }
        }
    
    def save_results(self, output_path: str, format: str = "json") -> bool:
        """
        שמירת תוצאות הניתוח לקובץ
        
        Args:
            output_path: נתיב לשמירת הקובץ
            format: פורמט הקובץ ("json", "yml", "csv")
            
        Returns:
            האם השמירה הצליחה
        """
        logger.info(f"שומר תוצאות בפורמט {format}: {output_path}")
        
        if not self.current_project:
            logger.error("אין פרויקט נוכחי לשמירה")
            return False
        
        try:
            if format.lower() == "json":
                # שמירה בפורמט JSON
                with open(output_path, 'w', encoding='utf-8') as f:
                    json.dump(self.current_project, f, ensure_ascii=False, indent=2)
            else:
                logger.error(f"פורמט לא נתמך: {format}")
                return False
            
            logger.info(f"תוצאות נשמרו: {output_path}")
            return True
        except Exception as e:
            logger.error(f"שגיאה בשמירת תוצאות: {str(e)}")
            return False
    
    def run_cli(self):
        """
        הפעלת ממשק שורת פקודה
        """
        parser = argparse.ArgumentParser(description='Smart Code Merger Pro 2.0')
        
        # הגדרת פקודות משנה
        subparsers = parser.add_subparsers(dest='command', help='פקודה לביצוע')
        
        # פקודת ניתוח קובץ
        analyze_file_parser = subparsers.add_parser('analyze-file', help='ניתוח קובץ בודד')
        analyze_file_parser.add_argument('file_path', help='נתיב לקובץ לניתוח')
        analyze_file_parser.add_argument('--output', help='נתיב לשמירת תוצאות')
        
        # פקודת ניתוח פרויקט
        analyze_project_parser = subparsers.add_parser('analyze-project', help='ניתוח פרויקט שלם')
        analyze_project_parser.add_argument('project_path', help='נתיב לתיקיית הפרויקט')
        analyze_project_parser.add_argument('--no-subfolders', action='store_true', help='לא לכלול תתי-תיקיות')
        analyze_project_parser.add_argument('--extensions', nargs='+', help='סיומות קבצים לניתוח')
        analyze_project_parser.add_argument('--output', help='נתיב לשמירת תוצאות')
        
        # פקודת ניתוח קשרים
        analyze_relationships_parser = subparsers.add_parser('analyze-relationships', help='ניתוח קשרים בין קבצים')
        analyze_relationships_parser.add_argument('files', nargs='+', help='רשימת קבצים לניתוח')
        analyze_relationships_parser.add_argument('--output', help='נתיב לשמירת תוצאות')
        analyze_relationships_parser.add_argument('--format', choices=['json', 'graphml', 'dot', 'gexf'], default='json', help='פורמט ייצוא')
        
        # פקודת ויזואליזציה
        visualize_parser = subparsers.add_parser('visualize', help='יצירת ויזואליזציה')
        visualize_parser.add_argument('--output', help='נתיב לשמירת ויזואליזציה')
        visualize_parser.add_argument('--format', choices=['png', 'svg', 'pdf', 'html'], default='html', help='פורמט ויזואליזציה')
        
        # פקודת מיזוג
        merge_parser = subparsers.add_parser('merge', help='מיזוג קבצים')
        merge_parser.add_argument('file1', help='נתיב לקובץ ראשון')
        merge_parser.add_argument('file2', help='נתיב לקובץ שני')
        merge_parser.add_argument('output', help='נתיב לקובץ התוצאה')
        merge_parser.add_argument('--strategy', choices=['smart', 'keep-left', 'keep-right', 'both'], default='smart', help='אסטרטגיית מיזוג')
        
        # פרמטרים גלובליים
        parser.add_argument('--config', help='נתיב לקובץ קונפיגורציה')
        parser.add_argument('--log-level', choices=['debug', 'info', 'warning', 'error'], default='info', help='רמת לוגים')
        
        # פירוק פרמטרים
        args = parser.parse_args()
        
        # הגדרת רמת לוגים
        log_levels = {
            'debug': logging.DEBUG,
            'info': logging.INFO,
            'warning': logging.WARNING,
            'error': logging.ERROR
        }
        logger.setLevel(log_levels[args.log_level])
        file_handler.setLevel(log_levels[args.log_level])
        console_handler.setLevel(log_levels[args.log_level])
        
        # ביצוע הפקודה
        if args.command == 'analyze-file':
            result = self.analyze_file(args.file_path)
            
            if args.output:
                with open(args.output, 'w', encoding='utf-8') as f:
                    json.dump(result, f, ensure_ascii=False, indent=2)
                logger.info(f"תוצאות נשמרו: {args.output}")
            else:
                print(json.dumps(result, ensure_ascii=False, indent=2))
                
        elif args.command == 'analyze-project':
            include_subfolders = not args.no_subfolders
            extensions = args.extensions if args.extensions else None
            
            result = self.analyze_project(args.project_path, include_subfolders, extensions)
            
            if args.output:
                self.save_results(args.output)
            else:
                print(json.dumps(result["statistics"], ensure_ascii=False, indent=2))
                
        elif args.command == 'analyze-relationships':
            result = self.analyze_relationships(args.files)
            
            if args.output:
                if args.format == 'json':
                    with open(args.output, 'w', encoding='utf-8') as f:
                        json.dump(result, f, ensure_ascii=False, indent=2)
                else:
                    self.export_graph(args.format, args.output)
                logger.info(f"תוצאות נשמרו: {args.output}")
            else:
                print(json.dumps(result, ensure_ascii=False, indent=2))
                
        elif args.command == 'visualize':
            output_path = self.visualize_relationships(args.format, args.output)
            if output_path:
                logger.info(f"ויזואליזציה נוצרה: {output_path}")
            else:
                logger.error("יצירת ויזואליזציה נכשלה")
                
        elif args.command == 'merge':
            result = self.merge_files(args.file1, args.file2, args.output, args.strategy)
            
            if result["success"]:
                logger.info(f"מיזוג הושלם: {args.output}")
                print(json.dumps(result["changes"], ensure_ascii=False, indent=2))
            else:
                logger.error("מיזוג נכשל")
                print(json.dumps(result, ensure_ascii=False, indent=2))
                
        else:
            parser.print_help()

# אם הסקריפט רץ ישירות
if __name__ == "__main__":
    merger = SmartCodeMerger()
    merger.run_cli()
