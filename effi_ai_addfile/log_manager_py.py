#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
מודול מנהל לוגים למאחד קוד חכם Pro 2.0
מערכת לוגים מתקדמת עם רמות לוג מרובות, תמיכה בפורמטים שונים וסינון

מחבר: Claude AI
גרסה: 1.0.0
תאריך: מאי 2025
"""

import os
import re
import sys
import json
import time
import logging
import datetime
from typing import Dict, List, Tuple, Any, Optional, Union, Set
from logging.handlers import RotatingFileHandler, TimedRotatingFileHandler
import threading
import traceback
import socket
import functools
import inspect
import queue

class ColoredFormatter(logging.Formatter):
    """
    מעצב לוגים צבעוני לפלט המסוף
    """
    
    # קודי צבעים ANSI
    COLORS = {
        'DEBUG': '\033[94m',     # כחול
        'INFO': '\033[92m',      # ירוק
        'WARNING': '\033[93m',   # צהוב
        'ERROR': '\033[91m',     # אדום
        'CRITICAL': '\033[1;91m', # אדום מודגש
        'RESET': '\033[0m'       # איפוס
    }
    
    def format(self, record: logging.LogRecord) -> str:
        """
        עיצוב רשומת לוג עם צבעים
        
        Args:
            record: רשומת הלוג
            
        Returns:
            המחרוזת המעוצבת
        """
        # שימוש במעצב הבסיסי
        formatted_msg = super().format(record)
        
        # הוספת צבע לפי רמת הלוג (רק אם התמיכה בצבע מופעלת)
        if hasattr(self, 'colored_output') and self.colored_output:
            level_name = record.levelname
            if level_name in self.COLORS:
                formatted_msg = f"{self.COLORS[level_name]}{formatted_msg}{self.COLORS['RESET']}"
        
        return formatted_msg

class LogManager:
    """
    מנהל לוגים מתקדם עם תמיכה ברמות לוג מרובות, פורמטים וסינון
    """
    
    # מופע יחיד (סינגלטון)
    _instance = None
    _loggers = {}
    
    # נעילה להגנה על פעולות מקבילות
    _lock = threading.RLock()
    
    # הגדרות גלובליות
    _global_config = {
        "default_level": logging.INFO,
        "log_dir": "logs",
        "default_format": "%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        "date_format": "%Y-%m-%d %H:%M:%S",
        "file_enabled": True,
        "console_enabled": True,
        "colored_output": True,
        "max_file_size_mb": 10,
        "backup_count": 5,
        "rotate_when": "midnight",
        "rotate_interval": 1,
        "enable_context": True,
        "include_process_info": False,
        "include_thread_info": False,
        "include_logger_info": True,
        "include_full_path": False,
        "include_function": True,
        "include_line_number": True,
        "notify_levels": ["ERROR", "CRITICAL"],
        "notify_handler": None,
    }
    
    # רשימת התראות (מקסימום 100 התראות אחרונות)
    _alerts_queue = queue.Queue(maxsize=100)
    
    def __new__(cls, logger_name=None, config=None):
        """
        יצירת מופע יחיד של מנהל הלוגים (סינגלטון)
        
        Args:
            logger_name: שם הלוגר
            config: הגדרות ספציפיות ללוגר
            
        Returns:
            מופע של מנהל הלוגים
        """
        with cls._lock:
            if cls._instance is None:
                cls._instance = super(LogManager, cls).__new__(cls)
                cls._instance._initialized = False
            
            return cls._instance
    
    def __init__(self, logger_name=None, config=None):
        """
        אתחול מנהל הלוגים
        
        Args:
            logger_name: שם הלוגר
            config: הגדרות ספציפיות ללוגר
        """
        with self._lock:
            # אתחול רק פעם אחת
            if not hasattr(self, '_initialized') or not self._initialized:
                self._initialized = True
                
                # טעינת הגדרות מקובץ אם קיים
                self._load_config()
                
                # וידוא קיום תיקיית לוגים
                os.makedirs(self._global_config["log_dir"], exist_ok=True)
                
                # מטמון לוגרים
                self._loggers = {}
                
                # רישום בעת יציאה מהמערכת
                import atexit
                atexit.register(self._shutdown)
            
            # הגדרת שם לוגר ספציפי
            self.logger_name = logger_name or "root"
            
            # הגדרות ספציפיות ללוגר
            if config:
                self._update_specific_config(self.logger_name, config)
    
    def _load_config(self):
        """
        טעינת הגדרות מקובץ
        """
        try:
            # חיפוש קובץ הגדרות בתיקיית האפליקציה
            config_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "config.json")
            
            if os.path.exists(config_path):
                with open(config_path, 'r', encoding='utf-8') as f:
                    app_config = json.load(f)
                
                # חילוץ הגדרות לוגים אם קיימות
                if "logging" in app_config:
                    # עדכון ההגדרות הגלובליות
                    for key, value in app_config["logging"].items():
                        if key in self._global_config:
                            self._global_config[key] = value
        except Exception as e:
            print(f"שגיאה בטעינת הגדרות לוגים: {str(e)}")
    
    def _update_specific_config(self, logger_name: str, config: Dict[str, Any]):
        """
        עדכון הגדרות ספציפיות ללוגר
        
        Args:
            logger_name: שם הלוגר
            config: הגדרות לעדכון
        """
        # יצירת מחלקה להגדרות ספציפיות אם לא קיימת
        if not hasattr(self, "_specific_config"):
            self._specific_config = {}
        
        # יצירת הגדרות בסיס ללוגר
        if logger_name not in self._specific_config:
            self._specific_config[logger_name] = self._global_config.copy()
        
        # עדכון הגדרות ספציפיות
        for key, value in config.items():
            if key in self._specific_config[logger_name]:
                self._specific_config[logger_name][key] = value
    
    def get_config(self, logger_name: str = None) -> Dict[str, Any]:
        """
        קבלת הגדרות לוגר
        
        Args:
            logger_name: שם הלוגר (או None להגדרות גלובליות)
            
        Returns:
            מילון הגדרות
        """
        if logger_name and hasattr(self, "_specific_config") and logger_name in self._specific_config:
            return self._specific_config[logger_name]
        
        return self._global_config.copy()
    
    def _get_level_name(self, level) -> str:
        """
        המרת רמת לוג למחרוזת
        
        Args:
            level: רמת הלוג (מספר או מחרוזת)
            
        Returns:
            שם רמת הלוג
        """
        if isinstance(level, str):
            return level.upper()
        
        return logging.getLevelName(level)
    
    def _get_level_value(self, level) -> int:
        """
        המרת רמת לוג למספר
        
        Args:
            level: רמת הלוג (מספר או מחרוזת)
            
        Returns:
            ערך מספרי של רמת הלוג
        """
        if isinstance(level, int):
            return level
        
        # המרת מחרוזת לרמה מספרית
        if isinstance(level, str):
            level = level.upper()
            if hasattr(logging, level):
                return getattr(logging, level)
        
        # ברירת מחדל
        return logging.INFO
    
    def _create_formatter(self, config: Dict[str, Any], colored: bool = False) -> logging.Formatter:
        """
        יצירת מעצב לוג
        
        Args:
            config: הגדרות
            colored: האם להשתמש בצבעים
            
        Returns:
            מעצב לוג מותאם
        """
        # הכנת פורמט בסיסי
        log_format = config.get("default_format")
        date_format = config.get("date_format")
        
        # הוספת מידע נוסף לפי הגדרות
        extra_info = []
        
        if config.get("include_process_info"):
            log_format = f"%(process)d - {log_format}"
        
        if config.get("include_thread_info"):
            log_format = f"%(threadName)s - {log_format}"
        
        if config.get("include_logger_info"):
            # לוגר כבר מופיע בפורמט הבסיסי (%(name)s)
            pass
        
        # מידע על מיקום הקוד
        location_info = []
        
        if config.get("include_full_path"):
            location_info.append("%(pathname)s")
        elif config.get("include_filename", True):
            location_info.append("%(filename)s")
        
        if config.get("include_function"):
            location_info.append("%(funcName)s")
        
        if config.get("include_line_number"):
            location_info.append("line:%(lineno)d")
        
        # הוספת מידע מיקום
        if location_info:
            location_str = ":".join(location_info)
            log_format = f"{log_format} [{location_str}]"
        
        # בחירת סוג המעצב
        if colored:
            formatter = ColoredFormatter(log_format, date_format)
            formatter.colored_output = config.get("colored_output", True)
        else:
            formatter = logging.Formatter(log_format, date_format)
        
        return formatter
    
    def get_logger(self, logger_name: str = None) -> logging.Logger:
        """
        קבלת לוגר מוגדר
        
        Args:
            logger_name: שם הלוגר (או None ללוגר נוכחי)
            
        Returns:
            אובייקט לוגר
        """
        # שימוש בשם שהוגדר באתחול אם לא סופק שם
        name = logger_name or self.logger_name
        
        # בדיקה אם הלוגר קיים במטמון
        if name in self._loggers:
            return self._loggers[name]
        
        with self._lock:
            # בדיקה נוספת בתוך מנעול (למניעת מרוץ)
            if name in self._loggers:
                return self._loggers[name]
            
            # קבלת הגדרות ללוגר
            config = self.get_config(name)
            
            # קבלת לוגר וניקוי הטיפולים הקיימים
            logger = logging.getLogger(name)
            logger.handlers = []
            
            # הגדרת רמת לוג
            logger.setLevel(config.get("default_level", logging.INFO))
            
            # הוספת טיפולים
            
            # טיפול קובץ
            if config.get("file_enabled", True):
                self._add_file_handler(logger, config)
            
            # טיפול מסוף
            if config.get("console_enabled", True):
                self._add_console_handler(logger, config)
            
            # שמירה במטמון
            self._loggers[name] = logger
            
            return logger
    
    def _add_file_handler(self, logger: logging.Logger, config: Dict[str, Any]):
        """
        הוספת טיפול קובץ ללוגר
        
        Args:
            logger: אובייקט לוגר
            config: הגדרות
        """
        log_dir = config.get("log_dir", "logs")
        
        # בדיקה אם התיקייה קיימת
        os.makedirs(log_dir, exist_ok=True)
        
        # שם קובץ מבוסס על שם הלוגר
        log_file = os.path.join(log_dir, f"{logger.name.replace('.', '_')}.log")
        
        # בחירת סוג הטיפול (לפי גודל או זמן)
        if config.get("rotate_when"):
            # סיבוב לפי זמן
            handler = TimedRotatingFileHandler(
                log_file,
                when=config.get("rotate_when", "midnight"),
                interval=config.get("rotate_interval", 1),
                backupCount=config.get("backup_count", 5),
                encoding='utf-8'
            )
        else:
            # סיבוב לפי גודל
            max_bytes = config.get("max_file_size_mb", 10) * 1024 * 1024
            handler = RotatingFileHandler(
                log_file,
                maxBytes=max_bytes,
                backupCount=config.get("backup_count", 5),
                encoding='utf-8'
            )
        
        # הגדרת מעצב
        formatter = self._create_formatter(config, colored=False)
        handler.setFormatter(formatter)
        
        # הוספת הטיפול ללוגר
        logger.addHandler(handler)
    
    def _add_console_handler(self, logger: logging.Logger, config: Dict[str, Any]):
        """
        הוספת טיפול מסוף ללוגר
        
        Args:
            logger: אובייקט לוגר
            config: הגדרות
        """
        # יצירת טיפול מסוף
        handler = logging.StreamHandler()
        
        # הגדרת מעצב צבעוני
        formatter = self._create_formatter(config, colored=True)
        handler.setFormatter(formatter)
        
        # הוספת הטיפול ללוגר
        logger.addHandler(handler)
    
    def _log_with_context(self, logger: logging.Logger, level: int, msg: str, *args, **kwargs):
        """
        רישום לוג עם הקשר נוסף
        
        Args:
            logger: אובייקט לוגר
            level: רמת הלוג
            msg: הודעת הלוג
            args: ארגומנטים נוספים
            kwargs: ארגומנטים נוספים עם מפתחות
        """
        # הוספת מידע הקשר
        if "extra" not in kwargs:
            kwargs["extra"] = {}
        
        # הוספת מידע על הפונקציה הקוראת
        frame = inspect.currentframe().f_back.f_back  # דילוג על 2 פונקציות פנימיות
        code = frame.f_code
        
        kwargs["extra"]["function"] = code.co_name
        kwargs["extra"]["filename"] = os.path.basename(code.co_filename)
        kwargs["extra"]["lineno"] = frame.f_lineno
        kwargs["extra"]["pathname"] = code.co_filename
        
        # שליחת הודעת הלוג
        logger.log(level, msg, *args, **kwargs)
        
        # בדיקה אם יש לשלוח התראה
        config = self.get_config(logger.name)
        level_name = logging.getLevelName(level)
        
        if level_name in config.get("notify_levels", ["ERROR", "CRITICAL"]):
            self._send_notification(level_name, msg, logger.name)
    
    def _send_notification(self, level_name: str, msg: str, logger_name: str):
        """
        שליחת התראה על הודעת לוג
        
        Args:
            level_name: שם רמת הלוג
            msg: הודעת הלוג
            logger_name: שם הלוגר
        """
        # הכנת הודעת התראה
        alert = {
            "timestamp": datetime.datetime.now().isoformat(),
            "level": level_name,
            "message": msg,
            "logger": logger_name
        }
        
        # הוספה לתור ההתראות (אם יש מקום)
        try:
            self._alerts_queue.put_nowait(alert)
        except queue.Full:
            pass
        
        # שליחת התראה אם הוגדר טיפול התראות
        config = self.get_config(logger_name)
        notify_handler = config.get("notify_handler")
        
        if notify_handler and callable(notify_handler):
            try:
                notify_handler(alert)
            except Exception as e:
                print(f"שגיאה בשליחת התראה: {str(e)}")
    
    def set_notify_handler(self, handler):
        """
        הגדרת טיפול התראות
        
        Args:
            handler: פונקציה לטיפול בהתראות
        """
        self._global_config["notify_handler"] = handler
    
    def get_alerts(self, limit: int = 10) -> List[Dict[str, Any]]:
        """
        קבלת התראות אחרונות
        
        Args:
            limit: מספר ההתראות המקסימלי
            
        Returns:
            רשימת התראות
        """
        alerts = []
        count = 0
        
        # שליפה מתור ההתראות (עד למגבלה)
        while count < limit and not self._alerts_queue.empty():
            try:
                alerts.append(self._alerts_queue.get_nowait())
                count += 1
            except queue.Empty:
                break
        
        # החזרת ההתראות למקומן (בסדר הפוך)
        for alert in reversed(alerts):
            try:
                self._alerts_queue.put_nowait(alert)
            except queue.Full:
                break
        
        return alerts
    
    def debug(self, msg, *args, **kwargs):
        """רישום הודעת DEBUG"""
        logger = self.get_logger()
        self._log_with_context(logger, logging.DEBUG, msg, *args, **kwargs)
    
    def info(self, msg, *args, **kwargs):
        """רישום הודעת INFO"""
        logger = self.get_logger()
        self._log_with_context(logger, logging.INFO, msg, *args, **kwargs)
    
    def warning(self, msg, *args, **kwargs):
        """רישום הודעת WARNING"""
        logger = self.get_logger()
        self._log_with_context(logger, logging.WARNING, msg, *args, **kwargs)
    
    def error(self, msg, *args, **kwargs):
        """רישום הודעת ERROR"""
        logger = self.get_logger()
        
        # הוספת מידע על חריגה אם קיים
        if "exc_info" not in kwargs and sys.exc_info()[0] is not None:
            kwargs["exc_info"] = True
        
        self._log_with_context(logger, logging.ERROR, msg, *args, **kwargs)
    
    def critical(self, msg, *args, **kwargs):
        """רישום הודעת CRITICAL"""
        logger = self.get_logger()
        
        # הוספת מידע על חריגה אם קיים
        if "exc_info" not in kwargs and sys.exc_info()[0] is not None:
            kwargs["exc_info"] = True
        
        self._log_with_context(logger, logging.CRITICAL, msg, *args, **kwargs)
    
    def exception(self, msg, *args, **kwargs):
        """רישום הודעת חריגה (שקולה ל-ERROR עם exc_info=True)"""
        kwargs["exc_info"] = True
        self.error(msg, *args, **kwargs)
    
    def set_level(self, level):
        """
        הגדרת רמת לוג
        
        Args:
            level: רמת הלוג החדשה
        """
        level_value = self._get_level_value(level)
        logger = self.get_logger()
        logger.setLevel(level_value)
    
    def add_custom_level(self, level_name: str, level_value: int):
        """
        הוספת רמת לוג מותאמת אישית
        
        Args:
            level_name: שם הרמה
            level_value: ערך מספרי (10-50)
        """
        # וידוא שהערך בתחום החוקי
        if not (10 <= level_value <= 50):
            raise ValueError(f"ערך רמת לוג חייב להיות בין 10 ל-50, התקבל: {level_value}")
        
        # הוספת רמה חדשה
        level_name = level_name.upper()
        logging.addLevelName(level_value, level_name)
        
        # הוספת פונקציה דינמית לרישום ברמה החדשה
        def log_with_custom_level(self, msg, *args, **kwargs):
            logger = self.get_logger()
            self._log_with_context(logger, level_value, msg, *args, **kwargs)
        
        # הוספת המתודה למחלקה
        setattr(LogManager, level_name.lower(), log_with_custom_level)
    
    def get_log_files(self) -> List[str]:
        """
        קבלת רשימת קבצי לוג
        
        Returns:
            רשימת נתיבי קבצי לוג
        """
        log_dir = self._global_config.get("log_dir", "logs")
        log_files = []
        
        try:
            if os.path.exists(log_dir) and os.path.isdir(log_dir):
                for file in os.listdir(log_dir):
                    if file.endswith(".log") or ".log." in file:
                        log_files.append(os.path.join(log_dir, file))
        except Exception as e:
            print(f"שגיאה בקבלת קבצי לוג: {str(e)}")
        
        return log_files
    
    def get_log_content(self, log_file: str, limit: int = 100) -> List[str]:
        """
        קבלת תוכן קובץ לוג
        
        Args:
            log_file: נתיב קובץ הלוג
            limit: מספר השורות המקסימלי
            
        Returns:
            רשימת שורות מהקובץ
        """
        try:
            if not os.path.exists(log_file):
                return []
            
            with open(log_file, 'r', encoding='utf-8', errors='ignore') as f:
                # קריאת השורות האחרונות
                lines = f.readlines()
                
                # החזרת השורות האחרונות (מוגבל למקסימום)
                return lines[-limit:]
        except Exception as e:
            print(f"שגיאה בקריאת קובץ לוג {log_file}: {str(e)}")
            return []
    
    def add_system_info(self, logger: logging.Logger = None):
        """
        הוספת מידע מערכת ללוג
        
        Args:
            logger: לוגר ספציפי או None ללוגר ברירת מחדל
        """
        if logger is None:
            logger = self.get_logger()
        
        # איסוף מידע מערכת
        system_info = {
            "hostname": socket.gethostname(),
            "platform": sys.platform,
            "python_version": sys.version,
            "timestamp": datetime.datetime.now().isoformat(),
            "pid": os.getpid()
        }
        
        # רישום מידע מערכת
        logger.info(f"מידע מערכת: {json.dumps(system_info, ensure_ascii=False)}")
    
    def log_function_call(self, func=None, level="DEBUG"):
        """
        דקורטור לרישום קריאות לפונקציה
        
        Args:
            func: הפונקציה לדקורציה
            level: רמת הלוג
            
        Returns:
            פונקציה מקושטת
        """
        def decorator(func):
            @functools.wraps(func)
            def wrapper(*args, **kwargs):
                # רישום קריאה לפונקציה
                logger = self.get_logger()
                level_value = self._get_level_value(level)
                
                self._log_with_context(
                    logger, 
                    level_value, 
                    f"קריאה לפונקציה {func.__name__} עם הפרמטרים: args={args}, kwargs={kwargs}"
                )
                
                # מדידת זמן ריצה
                start_time = time.time()
                
                try:
                    result = func(*args, **kwargs)
                    # רישום סיום מוצלח
                    duration = time.time() - start_time
                    self._log_with_context(
                        logger,
                        level_value,
                        f"הפונקציה {func.__name__} הסתיימה בהצלחה לאחר {duration:.4f} שניות"
                    )
                    return result
                except Exception as e:
                    # רישום שגיאה
                    duration = time.time() - start_time
                    self._log_with_context(
                        logger,
                        logging.ERROR,
                        f"שגיאה בפונקציה {func.__name__} לאחר {duration:.4f} שניות: {str(e)}",
                        exc_info=True
                    )
                    raise
                
            return wrapper
        
        # אפשר לקרוא את הדקורטור עם או בלי פרמטרים
        if func is None:
            return decorator
        return decorator(func)
    
    def _shutdown(self):
        """
        סגירת כל הלוגרים בעת יציאה
        """
        for name, logger in self._loggers.items():
            for handler in logger.handlers:
                handler.close()
