/**
 * app.js - סקריפט JavaScript למודול מאחד קוד חכם Pro 2.0
 * מערכת Effi-AI-privet
 * גרסה 2.0.0
 */

// מאזין לטעינת הדף המלאה
document.addEventListener('DOMContentLoaded', function() {
    initializeApp();
});

/**
 * אתחול האפליקציה
 */
function initializeApp() {
    console.log('מאחד קוד חכם Pro 2.0 טעון');
    
    // אתחול רכיבי מערכת
    initializeUIComponents();
    initializeEventListeners();
    initializeGraphs();
    
    // אתחול יכולות PWA
    initializeServiceWorker();
    
    // הגדרות מרכזיות
    loadSettings();
    
    // כאשר האתחול הושלם, הסתר את מסך הטעינה
    hideLoadingScreen();
}

/**
 * אתחול רכיבי ממשק
 */
function initializeUIComponents() {
    // אתחול הדגשת קוד
    document.querySelectorAll('pre code').forEach((el) => {
        hljs.highlightElement(el);
    });
    
    // אתחול טולטיפים
    var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl);
    });
    
    // אתחול קופצים
    var popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'));
    var popoverList = popoverTriggerList.map(function (popoverTriggerEl) {
        return new bootstrap.Popover(popoverTriggerEl);
    });
    
    // אתחול נושא כהה/בהיר
    initializeTheme();
}

/**
 * אתחול גרפים וויזואליזציות
 */
function initializeGraphs() {
    // גרף שפות תכנות
    if (document.getElementById('languages-chart')) {
        var languagesCtx = document.getElementById('languages-chart').getContext('2d');
        var languagesChart = new Chart(languagesCtx, {
            type: 'pie',
            data: {
                labels: ['Python', 'JavaScript', 'TypeScript'],
                datasets: [{
                    data: [3, 0, 0],
                    backgroundColor: ['#3572A5', '#F7DF1E', '#007ACC']
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: {
                        position: 'right'
                    }
                }
            }
        });
    }
    
    // גרף שורות קוד
    if (document.getElementById('lines-chart')) {
        var linesCtx = document.getElementById('lines-chart').getContext('2d');
        var linesChart = new Chart(linesCtx, {
            type: 'bar',
            data: {
                labels: ['file_analyzer.py', 'relationship_graph.py', 'module.py'],
                datasets: [{
                    label: 'שורות קוד',
                    data: [820, 650, 50],
                    backgroundColor: 'rgba(54, 162, 235, 0.5)',
                    borderColor: 'rgba(54, 162, 235, 1)',
                    borderWidth: 1
                }, {
                    label: 'הערות',
                    data: [150, 120, 10],
                    backgroundColor: 'rgba(255, 206, 86, 0.5)',
                    borderColor: 'rgba(255, 206, 86, 1)',
                    borderWidth: 1
                }, {
                    label: 'שורות ריקות',
                    data: [130, 100, 5],
                    backgroundColor: 'rgba(75, 192, 192, 0.5)',
                    borderColor: 'rgba(75, 192, 192, 1)',
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                scales: {
                    y: {
                        beginAtZero: true
                    }
                }
            }
        });
    }
    
    // גרף מורכבות ציקלומטית
    if (document.getElementById('complexity-chart')) {
        var complexityCtx = document.getElementById('complexity-chart').getContext('2d');
        var complexityChart = new Chart(complexityCtx, {
            type: 'radar',
            data: {
                labels: ['file_analyzer.py', 'relationship_graph.py', 'module.py'],
                datasets: [{
                    label: 'מורכבות ציקלומטית',
                    data: [5.2, 4.3, 2.1],
                    fill: true,
                    backgroundColor: 'rgba(255, 99, 132, 0.2)',
                    borderColor: 'rgb(255, 99, 132)',
                    pointBackgroundColor: 'rgb(255, 99, 132)',
                    pointBorderColor: '#fff',
                    pointHoverBackgroundColor: '#fff',
                    pointHoverBorderColor: 'rgb(255, 99, 132)'
                }]
            },
            options: {
                elements: {
                    line: {
                        borderWidth: 3
                    }
                },
                scales: {
                    r: {
                        angleLines: {
                            display: true
                        },
                        suggestedMin: 0,
                        suggestedMax: 10
                    }
                }
            }
        });
    }
    
    // גרף עומק קינון
    if (document.getElementById('nesting-chart')) {
        var nestingCtx = document.getElementById('nesting-chart').getContext('2d');
        var nestingChart = new Chart(nestingCtx, {
            type: 'radar',
            data: {
                labels: ['file_analyzer.py', 'relationship_graph.py', 'module.py'],
                datasets: [{
                    label: 'עומק קינון מקסימלי',
                    data: [4, 3, 2],
                    fill: true,
                    backgroundColor: 'rgba(54, 162, 235, 0.2)',
                    borderColor: 'rgb(54, 162, 235)',
                    pointBackgroundColor: 'rgb(54, 162, 235)',
                    pointBorderColor: '#fff',
                    pointHoverBackgroundColor: '#fff',
                    pointHoverBorderColor: 'rgb(54, 162, 235)'
                }]
            },
            options: {
                elements: {
                    line: {
                        borderWidth: 3
                    }
                },
                scales: {
                    r: {
                        angleLines: {
                            display: true
                        },
                        suggestedMin: 0,
                        suggestedMax: 5
                    }
                }
            }
        });
    }
    
    // אתחול גרף תלויות
    if (document.getElementById('dependencies-chart')) {
        var dependencyNodes = new vis.DataSet([
            { id: 1, label: 'module.py', shape: 'box', color: { background: '#3572A5', border: '#2980b9' } },
            { id: 2, label: 'file_analyzer.py', shape: 'box', color: { background: '#3572A5', border: '#2980b9' } },
            { id: 3, label: 'relationship_graph.py', shape: 'box', color: { background: '#3572A5', border: '#2980b9' } }
        ]);

        var dependencyEdges = new vis.DataSet([
            { from: 1, to: 2, arrows: 'to' },
            { from: 1, to: 3, arrows: 'to' },
            { from: 3, to: 2, arrows: 'to' }
        ]);

        var dependencyContainer = document.getElementById('dependencies-chart');
        var dependencyData = {
            nodes: dependencyNodes,
            edges: dependencyEdges
        };
        var dependencyOptions = {
            nodes: {
                shape: 'box',
                borderWidth: 1,
                shadow: true
            },
            edges: {
                width: 1,
                smooth: {
                    type: 'continuous'
                }
            },
            physics: {
                stabilization: false,
                barnesHut: {
                    gravitationalConstant: -2000,
                    centralGravity: 0.3,
                    springLength: 95,
                    springConstant: 0.04
                }
            }
        };
        var dependencyNetwork = new vis.Network(dependencyContainer, dependencyData, dependencyOptions);
    }
    
    // אתחול גרף קשרים
    if (document.getElementById('graph-container')) {
        var graphNodes = new vis.DataSet([
            { id: 1, label: 'module.py', color: { background: '#3572A5' } },
            { id: 2, label: 'file_analyzer.py', color: { background: '#3572A5' } },
            { id: 3, label: 'relationship_graph.py', color: { background: '#3572A5' } },
            { id: 4, label: 'os', color: { background: '#cccccc' } },
            { id: 5, label: 're', color: { background: '#cccccc' } },
            { id: 6, label: 'json', color: { background: '#cccccc' } },
            { id: 7, label: 'logging', color: { background: '#cccccc' } },
            { id: 8, label: 'networkx', color: { background: '#cccccc' } },
            { id: 9, label: 'matplotlib', color: { background: '#cccccc' } }
        ]);
        
        var graphEdges = new vis.DataSet([
            { from: 1, to: 2, arrows: 'to' },
            { from: 1, to: 3, arrows: 'to' },
            { from: 2, to: 4, arrows: 'to' },
            { from: 2, to: 5, arrows: 'to' },
            { from: 2, to: 6, arrows: 'to' },
            { from: 2, to: 7, arrows: 'to' },
            { from: 2, to: 8, arrows: 'to' },
            { from: 3, to: 4, arrows: 'to' },
            { from: 3, to: 6, arrows: 'to' },
            { from: 3, to: 7, arrows: 'to' },
            { from: 3, to: 8, arrows: 'to' },
            { from: 3, to: 9, arrows: 'to' },
            { from: 3, to: 2, arrows: 'to', dashes: true }
        ]);
        
        var graphData = {
            nodes: graphNodes,
            edges: graphEdges
        };
        
        var graphOptions = {
            nodes: {
                shape: 'dot',
                size: 16,
                font: {
                    size: 12
                },
                borderWidth: 1,
                shadow: true
            },
            edges: {
                width: 1,
                smooth: {
                    type: 'continuous'
                }
            },
            physics: {
                enabled: true,
                barnesHut: {
                    gravitationalConstant: -2000,
                    centralGravity: 0.1,
                    springLength: 95,
                    springConstant: 0.04,
                    damping: 0.09
                },
                stabilization: {
                    iterations: 200
                }
            },
            interaction: {
                navigationButtons: true,
                keyboard: true
            }
        };
        
        var graph = new vis.Network(document.getElementById('graph-container'), graphData, graphOptions);
        
        // כאשר בוחרים קודקוד בגרף
        graph.on('selectNode', function(params) {
            document.getElementById('selected-node-info-card').style.display = 'block';
            document.getElementById('selected-node-name').textContent = graphNodes.get(params.nodes[0]).label;
        });
        
        // כפתורי שליטה בגרף
        var zoomInBtn = document.getElementById('zoom-in-btn');
        var zoomOutBtn = document.getElementById('zoom-out-btn');
        var fitBtn = document.getElementById('fit-btn');
        
        if (zoomInBtn) {
            zoomInBtn.addEventListener('click', function() {
                graph.zoom(1.2);
            });
        }
        
        if (zoomOutBtn) {
            zoomOutBtn.addEventListener('click', function() {
                graph.zoom(0.8);
            });
        }
        
        if (fitBtn) {
            fitBtn.addEventListener('click', function() {
                graph.fit();
            });
        }
        
        // סגירת פאנל מידע על קודקוד
        var closeNodeInfoBtn = document.getElementById('close-node-info');
        if (closeNodeInfoBtn) {
            closeNodeInfoBtn.addEventListener('click', function() {
                document.getElementById('selected-node-info-card').style.display = 'none';
            });
        }
    }
    
    // גרף סיכום אבטחה
    if (document.getElementById('security-summary-chart')) {
        var securityCtx = document.getElementById('security-summary-chart').getContext('2d');
        var securityChart = new Chart(securityCtx, {
            type: 'doughnut',
            data: {
                labels: ['קריטי', 'גבוה', 'בינוני', 'נמוך'],
                datasets: [{
                    data: [2, 5, 8, 12],
                    backgroundColor: ['#e74c3c', '#f39c12', '#3498db', '#2ecc71']
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: {
                        position: 'right'
                    }
                }
            }
        });
    }
}

/**
 * אתחול מאזיני אירועים
 */
function initializeEventListeners() {
    // לחיצה על כפתור ניתוח
    var analyzeBtn = document.getElementById('analyze-btn');
    if (analyzeBtn) {
        analyzeBtn.addEventListener('click', function() {
            simulateAnalysis(this);
        });
    }
    
    // לחיצה על כפתור מיזוג
    var mergeBtn = document.getElementById('merge-btn');
    if (mergeBtn) {
        mergeBtn.addEventListener('click', function() {
            simulateMerge(this);
        });
    }
    
    // לחיצה על כפתור סריקה
    var scanBtn = document.getElementById('scan-btn');
    if (scanBtn) {
        scanBtn.addEventListener('click', function() {
            simulateScan(this);
        });
    }
    
    // לחיצה על כפתורי שמירת הגדרות
    var saveSettingsBtn = document.getElementById('save-settings-btn');
    if (saveSettingsBtn) {
        saveSettingsBtn.addEventListener('click', function() {
            saveSettings(this);
        });
    }
    
    var saveAnalysisSettingsBtn = document.getElementById('save-analysis-settings-btn');
    if (saveAnalysisSettingsBtn) {
        saveAnalysisSettingsBtn.addEventListener('click', function() {
            saveSettings(this);
        });
    }
    
    // פתיחת חלון פרטי קובץ
    document.querySelectorAll('.file-details-link').forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            var fileName = this.getAttribute('data-filename');
            openFileDetailsModal(fileName);
        });
    });
    
    // שינוי נושא
    var themeSelector = document.getElementById('ui-theme');
    if (themeSelector) {
        themeSelector.addEventListener('change', function() {
            changeTheme(this.value);
        });
    }
    
    // שינוי שפה
    var languageSelector = document.getElementById('ui-language');
    if (languageSelector) {
        languageSelector.addEventListener('change', function() {
            changeLanguage(this.value);
        });
    }
    
    // מעבר לשוניות
    document.querySelectorAll('button[data-bs-toggle="tab"]').forEach(button => {
        button.addEventListener('shown.bs.tab', function(e) {
            // כאשר נבחרה לשונית חדשה, עדכן את ה-URL
            updateUrlHash(e.target.getAttribute('aria-controls'));
        });
    });
    
    // כפתור חזרה למעלה
    var backToTopBtn = document.getElementById('back-to-top');
    if (backToTopBtn) {
        backToTopBtn.addEventListener('click', function() {
            window.scrollTo({ top: 0, behavior: 'smooth' });
        });
        
        // הצג/הסתר את הכפתור בהתאם לגלילה
        window.addEventListener('scroll', function() {
            if (window.scrollY > 300) {
                backToTopBtn.classList.add('show');
            } else {
                backToTopBtn.classList.remove('show');
            }
        });
    }
}

/**
 * אתחול נושא כהה/בהיר
 */
function initializeTheme() {
    var storedTheme = localStorage.getItem('theme') || 'light';
    var themeSelector = document.getElementById('ui-theme');
    
    // הגדר את הנושא הנבחר
    if (themeSelector) {
        themeSelector.value = storedTheme;
    }
    
    // החל את הנושא
    changeTheme(storedTheme);
}

/**
 * שינוי נושא הממשק
 * @param {string} theme - הנושא הנבחר ('light', 'dark' או 'auto')
 */
function changeTheme(theme) {
    if (theme === 'auto') {
        // השתמש בהעדפת מערכת ההפעלה
        if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
            document.body.classList.add('dark-theme');
        } else {
            document.body.classList.remove('dark-theme');
        }
        
        // האזן לשינויים בהעדפת המערכת
        window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', function(e) {
            if (e.matches) {
                document.body.classList.add('dark-theme');
            } else {
                document.body.classList.remove('dark-theme');
            }
        });
    } else if (theme === 'dark') {
        document.body.classList.add('dark-theme');
    } else {
        document.body.classList.remove('dark-theme');
    }
    
    // שמור את הנושא הנבחר
    localStorage.setItem('theme', theme);
}

/**
 * שינוי שפת הממשק
 * @param {string} language - השפה הנבחרת
 */
function changeLanguage(language) {
    // בדוגמה זו נחליף שפה רק עבור כמה אלמנטים
    if (language === 'en') {
        // דוגמה לשינוי שפה לאנגלית
        document.querySelector('header h1').textContent = 'Smart Code Merger Pro 2.0';
        document.querySelector('header p.lead').textContent = 'Analysis, detection and merging of code with advanced AI technologies';
    } else {
        // שפת ברירת מחדל - עברית
        document.querySelector('header h1').textContent = 'מאחד קוד חכם Pro 2.0';
        document.querySelector('header p.lead').textContent = 'ניתוח, זיהוי ואיחוד קוד חכם בעזרת טכנולוגיות AI מתקדמות';
    }
    
    // שמור את השפה הנבחרת
    localStorage.setItem('language', language);
}

/**
 * אתחול Service Worker עבור PWA
 */
function initializeServiceWorker() {
    if ('serviceWorker' in navigator) {
        navigator.serviceWorker.register('/service-worker.js').then(function(registration) {
            console.log('Service Worker נרשם בהצלחה:', registration.scope);
        }).catch(function(error) {
            console.log('רישום Service Worker נכשל:', error);
        });
    }
}

/**
 * טעינת הגדרות
 */
function loadSettings() {
    // טען הגדרות מאחסון מקומי
    var settings = JSON.parse(localStorage.getItem('settings')) || {};
    
    // החל הגדרות על אלמנטי הממשק
    if (settings.maxFileSize) {
        var maxFileSizeInput = document.getElementById('max-file-size');
        if (maxFileSizeInput) maxFileSizeInput.value = settings.maxFileSize;
    }
    
    if (settings.complexityThreshold) {
        var complexityThresholdInput = document.getElementById('complexity-threshold');
        if (complexityThresholdInput) complexityThresholdInput.value = settings.complexityThreshold;
    }
    
    if (settings.workersCount) {
        var workersCountInput = document.getElementById('workers-count');
        if (workersCountInput) workersCountInput.value = settings.workersCount;
    }
    
    if (settings.logLevel) {
        var logLevelSelect = document.getElementById('log-level');
        if (logLevelSelect) logLevelSelect.value = settings.logLevel;
    }
    
    if (settings.enableAnimations !== undefined) {
        var enableAnimationsCheckbox = document.getElementById('enable-animations');
        if (enableAnimationsCheckbox) enableAnimationsCheckbox.checked = settings.enableAnimations;
        
        // אם האנימציות מבוטלות, הוסף מחלקה לגוף הדף
        if (!settings.enableAnimations) {
            document.body.classList.add('no-animations');
        } else {
            document.body.classList.remove('no-animations');
        }
    }
    
    if (settings.autoSave !== undefined) {
        var autoSaveCheckbox = document.getElementById('auto-save');
        if (autoSaveCheckbox) autoSaveCheckbox.checked = settings.autoSave;
    }
    
    console.log('הגדרות נטענו');
}

/**
 * שמירת הגדרות
 * @param {HTMLElement} button - כפתור השמירה שנלחץ
 */
function saveSettings(button) {
    // שינוי מצב הכפתור למצב טעינה
    button.innerHTML = '<div class="spinner me-2"></div> שומר...';
    button.disabled = true;
    
    // אסוף הגדרות מהטופס
    var settings = {
        maxFileSize: parseInt(document.getElementById('max-file-size')?.value || 100),
        complexityThreshold: parseInt(document.getElementById('complexity-threshold')?.value || 10),
        workersCount: parseInt(document.getElementById('workers-count')?.value || 4),
        logLevel: document.getElementById('log-level')?.value || 'info',
        enableAnimations: document.getElementById('enable-animations')?.checked ?? true,
        autoSave: document.getElementById('auto-save')?.checked ?? true
    };
    
    // החל הגדרות
    if (!settings.enableAnimations) {
        document.body.classList.add('no-animations');
    } else {
        document.body.classList.remove('no-animations');
    }
    
    // שמור הגדרות לאחסון מקומי
    localStorage.setItem('settings', JSON.stringify(settings));
    
    // סימולציית שמירה
    setTimeout(function() {
        button.innerHTML = '<i class="fas fa-check me-1"></i> נשמר!';
        
        setTimeout(function() {
            if (button.id === 'save-settings-btn') {
                button.innerHTML = '<i class="fas fa-save me-1"></i> שמירת הגדרות';
            } else {
                button.innerHTML = '<i class="fas fa-save me-1"></i> שמירת הגדרות';
            }
            button.disabled = false;
        }, 1500);
    }, 1000);
}

/**
 * סימולציית ניתוח קבצים
 * @param {HTMLElement} button - כפתור הניתוח שנלחץ
 */
function simulateAnalysis(button) {
    // שינוי מצב הכפתור למצב טעינה
    button.innerHTML = '<div class="spinner me-2"></div> מנתח...';
    button.disabled = true;
    
    // סימולציית תהליך ניתוח
    setTimeout(function() {
        button.innerHTML = '<i class="fas fa-search me-1"></i> ניתוח';
        button.disabled = false;
        
        // הצגת תוצאות
        var resultsPane = document.getElementById('analyzer-tab');
        resultsPane.scrollIntoView({ behavior: 'smooth' });
        
        // הדגש את תיבת הסיכום
        var summaryBox = document.querySelector('.highlight-box');
        if (summaryBox) {
            summaryBox.classList.add('pulse');
            setTimeout(() => {
                summaryBox.classList.remove('pulse');
            }, 2000);
        }
    }, 2000);
}

/**
 * סימולציית מיזוג קבצים
 * @param {HTMLElement} button - כפתור המיזוג שנלחץ
 */
function simulateMerge(button) {
    // שינוי מצב הכפתור למצב טעינה
    button.innerHTML = '<div class="spinner me-2"></div> ממזג...';
    button.disabled = true;
    
    // עדכון סטטוס בזמן אמת
    var currentStep = document.getElementById('current-step');
    var progressBar = document.querySelector('.progress-bar');
    var stepTexts = ['ניתוח קבצים', 'זיהוי הבדלים', 'פתרון קונפליקטים', 'יצירת מיזוג'];
    var progress = [25, 50, 75, 100];
    
    var stepIndex = 0;
    var stepInterval = setInterval(function() {
        if (stepIndex < stepTexts.length) {
            currentStep.textContent = stepTexts[stepIndex];
            progressBar.style.width = progress[stepIndex] + '%';
            progressBar.setAttribute('aria-valuenow', progress[stepIndex]);
            stepIndex++;
        } else {
            clearInterval(stepInterval);
            
            // עדכון סטטוס לאחר סיום
            var statusBadge = document.getElementById('merge-status');
            if (statusBadge) {
                statusBadge.textContent = 'הושלם';
                statusBadge.className = 'status-badge badge-success';
            }
            
            // הסתרת ספינר
            var spinner = document.getElementById('merge-spinner');
            if (spinner) {
                spinner.style.display = 'none';
            }
            
            // החזרת הכפתור למצב הרגיל
            button.innerHTML = '<i class="fas fa-object-group me-1"></i> מיזוג קבצים';
            button.disabled = false;
        }
    }, 1000);
}

/**
 * סימולציית סריקת אבטחה
 * @param {HTMLElement} button - כפתור הסריקה שנלחץ
 */
function simulateScan(button) {
    // שינוי מצב הכפתור למצב טעינה
    button.innerHTML = '<div class="spinner me-2"></div> סורק...';
    button.disabled = true;
    
    // סימולציית תהליך סריקה
    setTimeout(function() {
        button.innerHTML = '<i class="fas fa-search me-1"></i> התחלת סריקה';
        button.disabled = false;
        
        // אנימציה לטבלת ממצאים
        var securityTable = document.querySelector('#security table');
        if (securityTable) {
            securityTable.classList.add('fade-in');
        }
    }, 2000);
}

/**
 * פתיחת מודל פרטי קובץ
 * @param {string} fileName - שם הקובץ להצגה
 */
function openFileDetailsModal(fileName) {
    var modal = document.getElementById('file-details-modal');
    if (!modal) return;
    
    // מילוי פרטי הקובץ במודל
    document.getElementById('modal-filename').textContent = fileName;
    
    // סימולציית טעינת נתונים נוספים
    // במקרה אמיתי, היינו מבצעים שליפת נתונים נוספים מהשרת או מהזיכרון
    
    // פתיחת המודל
    var modalInstance = new bootstrap.Modal(modal);
    modalInstance.show();
}

/**
 * עדכון האש (hash) ב-URL בהתאם ללשונית הנוכחית
 * @param {string} tabId - מזהה הלשונית הנוכחית
 */
function updateUrlHash(tabId) {
    if (history.pushState) {
        history.pushState(null, null, '#' + tabId);
    } else {
        location.hash = '#' + tabId;
    }
}

/**
 * הסתרת מסך טעינה
 */
function hideLoadingScreen() {
    var loadingScreen = document.getElementById('loading-screen');
    if (loadingScreen) {
        loadingScreen.classList.add('fade-out');
        setTimeout(() => {
            loadingScreen.remove();
        }, 500);
    }
}

/**
 * בדיקה אם דפדפן הלקוח תומך בכל התכונות הנדרשות
 * @returns {boolean} האם הדפדפן נתמך
 */
function checkBrowserSupport() {
    // בדיקת תמיכה ב-ES6
    try {
        eval('const x = (y) => y');
    } catch (e) {
        console.error('הדפדפן שלך לא תומך ב-JavaScript מודרני (ES6)');
        return false;
    }
    
    // בדיקת תמיכה ב-WebGL (לגרפים)
    var canvas = document.createElement('canvas');
    var gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
    if (!gl) {
        console.warn('הדפדפן שלך עשוי לא לתמוך ב-WebGL, חלק מהוויזואליזציות עלולות לא לעבוד');
    }
    
    // בדיקת תמיכה ב-LocalStorage
    if (!('localStorage' in window)) {
        console.error('הדפדפן שלך לא תומך באחסון מקומי (LocalStorage)');
        return false;
    }
    
    return true;
}

/**
 * ייצוא נתונים לפורמט מבוקש
 * @param {Object} data - הנתונים לייצוא
 * @param {string} format - פורמט הייצוא ('json', 'csv', 'pdf')
 * @param {string} fileName - שם הקובץ ליצירה
 */
function exportData(data, format, fileName) {
    if (!data) return;
    
    var content;
    var mimeType;
    
    switch (format.toLowerCase()) {
        case 'json':
            content = JSON.stringify(data, null, 2);
            mimeType = 'application/json';
            break;
        case 'csv':
            // המרה לגרישים מופרדת פסיקים
            content = convertToCSV(data);
            mimeType = 'text/csv';
            break;
        case 'pdf':
            // PDF דורש ספריות חיצוניות כמו jsPDF
            // כאן נסתפק בהודעה
            alert('ייצוא PDF עדיין לא נתמך במהדורה זו');
            return;
        default:
            console.error('פורמט לא נתמך:', format);
            return;
    }
    
    // יצירת קובץ להורדה
    var blob = new Blob([content], { type: mimeType });
    var url = URL.createObjectURL(blob);
    
    var a = document.createElement('a');
    a.href = url;
    a.download = fileName || `export.${format}`;
    document.body.appendChild(a);
    a.click();
    
    // ניקוי
    setTimeout(function() {
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
    }, 0);
}

/**
 * המרת אובייקט למבנה CSV
 * @param {Object|Array} data - הנתונים להמרה
 * @returns {string} תוכן ה-CSV
 */
function convertToCSV(data) {
    if (!data || (typeof data !== 'object' && !Array.isArray(data))) {
        return '';
    }
    
    // אם הנתונים הם מערך של אובייקטים
    if (Array.isArray(data) && data.length > 0 && typeof data[0] === 'object') {
        const headers = Object.keys(data[0]);
        const csvRows = [];
        
        // כותרות
        csvRows.push(headers.join(','));
        
        // נתונים
        for (const row of data) {
            const values = headers.map(header => {
                const value = row[header];
                // טיפול במקרים מיוחדים (מחרוזות עם פסיקים, וכו')
                return `"${String(value).replace(/"/g, '""')}"`;
            });
            csvRows.push(values.join(','));
        }
        
        return csvRows.join('\n');
    }
    
    // אם הנתונים הם אובייקט בודד
    const headers = Object.keys(data);
    const values = headers.map(header => {
        const value = data[header];
        return `"${String(value).replace(/"/g, '""')}"`;
    });
    
    return headers.join(',') + '\n' + values.join(',');
}

// ייצוא פונקציות ציבוריות
window.SmartCodeMerger = {
    analyzeFiles: simulateAnalysis,
    mergeFiles: simulateMerge,
    scanFiles: simulateScan,
    exportData: exportData,
    changeTheme: changeTheme,
    changeLanguage: changeLanguage
};
