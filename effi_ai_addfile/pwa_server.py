#!/usr/bin/env python3
"""
שרת PWA למאחד קוד חכם Pro 2.0

שרת Flask פשוט להרצת ממשק PWA ולחשיפת API של המערכת.
"""

import os
import sys
import json
import logging
import tempfile
import mimetypes
from flask import Flask, request, jsonify, send_from_directory, send_file, redirect, url_for
from flask_cors import CORS
from werkzeug.utils import secure_filename

# תיקון ה-PATH כדי לאפשר ייבוא מקבצים במיקום הנוכחי
current_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.append(current_dir)

# ייבוא המודול העיקרי
from module import SmartCodeMergerProModule

# יצירת אפליקציית Flask
app = Flask(__name__, static_folder='assets')
CORS(app)  # אפשור CORS לגישה מדפדפן

# אתחול המודול
module = SmartCodeMergerProModule()
if not module.initialize():
    print("שגיאה באתחול המודול. בדוק את הלוגים לפרטים נוספים.")
    sys.exit(1)

# הגדרת תיקיית העלאות
UPLOAD_FOLDER = os.path.join(current_dir, 'uploads')
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# הגדרת נתיב לתיקיית PWA
PWA_FOLDER = os.path.join(current_dir, 'pwa')

# הגדרת קובץ לוגים
log_dir = os.path.join(current_dir, 'logs')
os.makedirs(log_dir, exist_ok=True)
logging.basicConfig(
    filename=os.path.join(log_dir, 'pwa_server.log'),
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# קונפיגורציית Flask
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['MAX_CONTENT_LENGTH'] = 1024 * 1024 * 1024  # 1GB מקסימום להעלאה

# נתיבי PWA

@app.route('/')
def index():
    """דף הבית של האפליקציה"""
    return send_from_directory(PWA_FOLDER, 'index.html')

@app.route('/manifest.json')
def manifest():
    """קובץ manifest של PWA"""
    return send_from_directory(PWA_FOLDER, 'manifest.json')

@app.route('/service-worker.js')
def service_worker():
    """קובץ service worker של PWA"""
    return send_from_directory(PWA_FOLDER, 'service-worker.js')

@app.route('/assets/<path:path>')
def serve_static(path):
    """סטטיק פיילז (CSS, JS, תמונות)"""
    return send_from_directory('assets', path)

# נתיבי API

@app.route('/api/upload', methods=['POST'])
def upload_files():
    """העלאת קבצי ZIP"""
    if 'files' not in request.files:
        return jsonify({"success": False, "error": "לא נמצאו קבצים בבקשה"}), 400
    
    files = request.files.getlist('files')
    if not files or files[0].filename == '':
        return jsonify({"success": False, "error": "לא נבחרו קבצים"}), 400
    
    # שמירת הקבצים
    saved_files = []
    for file in files:
        if file and file.filename.endswith('.zip'):
            filename = secure_filename(file.filename)
            file_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
            file.save(file_path)
            
            file_info = {
                "name": filename,
                "path": file_path,
                "size": os.path.getsize(file_path)
            }
            saved_files.append(file_info)
    
    if not saved_files:
        return jsonify({"success": False, "error": "אין קבצי ZIP חוקיים"}), 400
    
    # עדכון המודול עם הקבצים שהועלו
    zip_files = [file["path"] for file in saved_files]
    module.select_zip_files(zip_files)
    
    return jsonify({"success": True, "files": saved_files})

@app.route('/api/set-target', methods=['POST'])
def set_target():
    """הגדרת תיקיית יעד"""
    data = request.json
    if not data or 'target_dir' not in data:
        return jsonify({"success": False, "error": "חסר נתיב יעד"}), 400
    
    target_dir = data['target_dir']
    
    # יצירת התיקייה אם לא קיימת
    full_path = os.path.join(current_dir, target_dir)
    os.makedirs(full_path, exist_ok=True)
    
    # הגדרת תיקיית יעד במודול
    result = module.set_target_directory(full_path)
    
    if result:
        return jsonify({"success": True, "target_dir": full_path})
    else:
        return jsonify({"success": False, "error": "שגיאה בהגדרת תיקיית יעד"}), 500

@app.route('/api/analyze', methods=['POST'])
def analyze_projects():
    """ניתוח פרויקטים"""
    data = request.json
    if not data:
        data = {}
    
    target_dir = data.get('target_dir')
    if target_dir:
        # יצירת התיקייה אם לא קיימת
        full_path = os.path.join(current_dir, target_dir)
        os.makedirs(full_path, exist_ok=True)
        
        # הגדרת תיקיית יעד במודול
        module.set_target_directory(full_path)
    
    # ביצוע ניתוח
    results = module.analyze_projects()
    
    if not results or not results.get('detected_projects'):
        return jsonify({
            "success": False,
            "error": "לא זוהו פרויקטים או שאירעה שגיאה בניתוח"
        }), 500
    
    return jsonify({
        "success": True,
        "projects": results.get('detected_projects', {}),
        "orphan_files": results.get('orphan_files', {})
    })

@app.route('/api/merge', methods=['POST'])
def merge_projects():
    """מיזוג פרויקטים"""
    data = request.json
    if not data or 'projects' not in data:
        return jsonify({"success": False, "error": "חסרים פרויקטים למיזוג"}), 400
    
    projects = data['projects']
    
    if not projects:
        return jsonify({"success": False, "error": "לא נבחרו פרויקטים"}), 400
    
    # ביצוע מיזוג לכל פרויקט
    merged_projects = []
    
    for project_id in projects:
        result = module.merge_project(project_id)
        
        if result and result.get('status') == 'success':
            merged_projects.append({
                "project_id": project_id,
                "project_name": result.get('project_name', project_id),
                "output_dir": result.get('output_dir', ''),
                "files_count": result.get('files_count', 0)
            })
    
    if not merged_projects:
        return jsonify({"success": False, "error": "שגיאה במיזוג פרויקטים"}), 500
    
    # יצירת ZIP מהתוצאה
    output_dir = merged_projects[0]['output_dir']
    zip_file = tempfile.NamedTemporaryFile(delete=False, suffix='.zip').name
    
    import zipfile
    with zipfile.ZipFile(zip_file, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for root, dirs, files in os.walk(output_dir):
            for file in files:
                file_path = os.path.join(root, file)
                zipf.write(file_path, os.path.relpath(file_path, output_dir))
    
    # יצירת קישור להורדה
    download_url = f'/api/download?file={os.path.basename(zip_file)}'
    
    return jsonify({
        "success": True,
        "merged_projects": merged_projects,
        "download_url": download_url,
        "temp_file": zip_file
    })

@app.route('/api/merge-multiple', methods=['POST'])
def merge_multiple():
    """מיזוג מרובה של פרויקטים"""
    data = request.json
    if not data or 'projects' not in data or 'target_name' not in data:
        return jsonify({"success": False, "error": "חסרים פרויקטים או שם יעד"}), 400
    
    projects = data['projects']
    target_name = data['target_name']
    
    if not projects or len(projects) < 2:
        return jsonify({"success": False, "error": "יש לבחור לפחות שני פרויקטים למיזוג מרובה"}), 400
    
    # ביצוע מיזוג מרובה
    result = module.merge_multiple_projects(projects, target_name)
    
    if not result or result.get('status') != 'success':
        return jsonify({
            "success": False,
            "error": result.get('error', "שגיאה במיזוג מרובה")
        }), 500
    
    # יצירת ZIP מהתוצאה
    output_dir = result.get('output_dir', '')
    zip_file = tempfile.NamedTemporaryFile(delete=False, suffix='.zip').name
    
    import zipfile
    with zipfile.ZipFile(zip_file, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for root, dirs, files in os.walk(output_dir):
            for file in files:
                file_path = os.path.join(root, file)
                zipf.write(file_path, os.path.relpath(file_path, output_dir))
    
    # יצירת קישור להורדה
    download_url = f'/api/download?file={os.path.basename(zip_file)}'
    
    return jsonify({
        "success": True,
        "target_name": target_name,
        "output_dir": output_dir,
        "files_count": result.get('files_count', 0),
        "download_url": download_url,
        "temp_file": zip_file
    })

@app.route('/api/file-content')
def get_file_content():
    """קבלת תוכן קובץ"""
    path = request.args.get('path')
    if not path:
        return jsonify({"success": False, "error": "חסר נתיב לקובץ"}), 400
    
    try:
        with open(path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        
        return jsonify({
            "success": True,
            "content": content,
            "path": path
        })
    except Exception as e:
        return jsonify({
            "success": False,
            "error": f"שגיאה בקריאת הקובץ: {str(e)}",
            "path": path
        }), 500

@app.route('/api/download')
def download_file():
    """הורדת קובץ ZIP"""
    file = request.args.get('file')
    if not file:
        return jsonify({"success": False, "error": "חסר קובץ להורדה"}), 400
    
    # חיפוש הקובץ בתיקיית temp
    temp_dir = tempfile.gettempdir()
    file_path = os.path.join(temp_dir, file)
    
    if not os.path.exists(file_path):
        return jsonify({"success": False, "error": "קובץ לא נמצא"}), 404
    
    return send_file(file_path, as_attachment=True, download_name=file)

@app.route('/api/versions/<path:file_path>')
def get_file_versions(file_path):
    """קבלת גרסאות של קובץ"""
    # המרת נתיב יחסי לנתיב מלא
    try:
        # לקרוא גרסאות מהקובץ
        versions = module.get_file_versions(file_path)
        
        return jsonify({
            "success": True,
            "file_path": file_path,
            "versions": versions
        })
    except Exception as e:
        return jsonify({
            "success": False,
            "error": f"שגיאה בקבלת גרסאות: {str(e)}",
            "file_path": file_path
        }), 500

@app.route('/api/compare-versions', methods=['POST'])
def compare_versions():
    """השוואת גרסאות"""
    data = request.json
    if not data or 'version1' not in data or 'version2' not in data:
        return jsonify({"success": False, "error": "חסרים מזהי גרסאות להשוואה"}), 400
    
    version1 = data['version1']
    version2 = data['version2']
    
    try:
        # השוואת גרסאות
        comparison = module.compare_file_versions(version1, version2)
        
        return jsonify({
            "success": True,
            "comparison": comparison
        })
    except Exception as e:
        return jsonify({
            "success": False,
            "error": f"שגיאה בהשוואת גרסאות: {str(e)}"
        }), 500

@app.route('/api/security-scan', methods=['POST'])
def security_scan():
    """סריקת אבטחה"""
    data = request.json
    if not data or 'project_id' not in data:
        return jsonify({"success": False, "error": "חסר מזהה פרויקט לסריקה"}), 400
    
    project_id = data['project_id']
    
    try:
        # סריקת אבטחה
        scan_results = module.scan_project_security(project_id)
        
        return jsonify({
            "success": True,
            "results": scan_results
        })
    except Exception as e:
        return jsonify({
            "success": False,
            "error": f"שגיאה בסריקת אבטחה: {str(e)}",
            "project_id": project_id
        }), 500

@app.route('/api/run-code', methods=['POST'])
def run_code():
    """הרצת קוד"""
    data = request.json
    if not data or 'code' not in data or 'language' not in data:
        return jsonify({"success": False, "error": "חסר קוד או שפה להרצה"}), 400
    
    code = data['code']
    language = data['language']
    parameters = data.get('parameters', {})
    
    try:
        # הרצת קוד
        temp_file = tempfile.NamedTemporaryFile(delete=False, suffix=f'.{language}')
        temp_file.write(code.encode('utf-8'))
        temp_file.close()
        
        run_results = module.run_code(temp_file.name, parameters)
        
        # ניקוי
        os.unlink(temp_file.name)
        
        return jsonify({
            "success": True,
            "results": run_results
        })
    except Exception as e:
        return jsonify({
            "success": False,
            "error": f"שגיאה בהרצת קוד: {str(e)}",
            "language": language
        }), 500

@app.route('/api/complete-code', methods=['POST'])
def complete_code():
    """השלמת קוד"""
    data = request.json
    if not data or 'code' not in data or 'language' not in data:
        return jsonify({"success": False, "error": "חסר קוד או שפה להשלמה"}), 400
    
    code = data['code']
    language = data['language']
    
    try:
        # זיהוי חלקים חסרים
        temp_file = tempfile.NamedTemporaryFile(delete=False, suffix=f'.{language}')
        temp_file.write(code.encode('utf-8'))
        temp_file.close()
        
        missing_parts = module.detect_missing_parts(temp_file.name)
        
        # השלמת חלקים חסרים
        completion_results = module.complete_code(temp_file.name, missing_parts.get('missing_parts', []))
        
        # ניקוי
        os.unlink(temp_file.name)
        
        return jsonify({
            "success": True,
            "results": completion_results
        })
    except Exception as e:
        return jsonify({
            "success": False,
            "error": f"שגיאה בהשלמת קוד: {str(e)}",
            "language": language
        }), 500

@app.route('/api/connect-remote', methods=['POST'])
def connect_remote():
    """התחברות לאחסון מרוחק"""
    data = request.json
    if not data or 'storage_type' not in data:
        return jsonify({"success": False, "error": "חסר סוג אחסון"}), 400
    
    storage_type = data['storage_type']
    connection_params = {k: v for k, v in data.items() if k != 'storage_type'}
    
    try:
        # התחברות לאחסון מרוחק
        connection_id = module.connect_remote_storage(storage_type, connection_params)
        
        if not connection_id:
            return jsonify({
                "success": False,
                "error": "שגיאה בהתחברות לאחסון מרוחק"
            }), 500
        
        return jsonify({
            "success": True,
            "connection_id": connection_id,
            "storage_type": storage_type
        })
    except Exception as e:
        return jsonify({
            "success": False,
            "error": f"שגיאה בהתחברות לאחסון מרוחק: {str(e)}",
            "storage_type": storage_type
        }), 500

@app.route('/api/list-remote-files')
def list_remote_files():
    """רשימת קבצים באחסון מרוחק"""
    path = request.args.get('path', '/')
    connection_id = request.args.get('connection_id')
    
    try:
        # רשימת קבצים
        files = module.list_remote_files(path, connection_id)
        
        return jsonify({
            "success": True,
            "files": files
        })
    except Exception as e:
        return jsonify({
            "success": False,
            "error": f"שגיאה בקבלת רשימת קבצים: {str(e)}",
            "path": path
        }), 500

@app.route('/api/download-remote-file', methods=['POST'])
def download_remote_file():
    """הורדת קובץ מאחסון מרוחק"""
    data = request.json
    if not data or 'remote_path' not in data:
        return jsonify({"success": False, "error": "חסר נתיב מרוחק"}), 400
    
    remote_path = data['remote_path']
    connection_id = data.get('connection_id')
    
    try:
        # יצירת קובץ זמני ליעד
        local_path = tempfile.NamedTemporaryFile(delete=False).name
        
        # הורדת הקובץ
        result = module.download_remote_file(remote_path, local_path, connection_id)
        
        if not result or result.get('status') != 'success':
            return jsonify({
                "success": False,
                "error": result.get('error', "שגיאה בהורדת קובץ")
            }), 500
        
        # יצירת קישור להורדה
        download_url = f'/api/download-file?file={os.path.basename(local_path)}&name={os.path.basename(remote_path)}'
        
        return jsonify({
            "success": True,
            "download_url": download_url,
            "remote_path": remote_path,
            "local_path": local_path
        })
    except Exception as e:
        return jsonify({
            "success": False,
            "error": f"שגיאה בהורדת קובץ: {str(e)}",
            "remote_path": remote_path
        }), 500

@app.route('/api/default-settings')
def default_settings():
    """הגדרות ברירת מחדל"""
    return jsonify({
        "theme": "auto",
        "animations": True,
        "version_management": True,
        "security_scanning": True,
        "code_running": True,
        "code_completion": True,
        "multi_file_view": True,
        "logging_level": "INFO"
    })

@app.route('/api/system-info')
def system_info():
    """מידע מערכת"""
    return jsonify({
        "module_name": module.name,
        "module_version": module.version,
        "supported_languages": [
            "python", "javascript", "typescript", "java", "c", "cpp", 
            "csharp", "go", "ruby", "php", "rust", "swift", "kotlin", 
            "scala", "bash", "html", "css", "xml", "json", "yaml"
        ],
        "supported_storage_types": [
            "local", "ssh", "s3", "ftp", "webdav", "smb", "nfs"
        ],
        "new_features": [
            "ניהול גרסאות",
            "סריקות אבטחה",
            "הרצת קוד",
            "השלמת קוד",
            "אחסון מרוחק",
            "מיזוג מרובה",
            "ניתוח קשרים מעמיק"
        ]
    })

# הרצת השרת
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)