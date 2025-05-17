                // יצירת מקרא צבעים
                function createColorLegend() {
                    const colors = {};
                    const types = {};
                    
                    // איסוף צבעים ייחודיים וסוגי קודקודים
                    graphData.nodes.forEach(node => {
                        if (node.type) {
                            types[node.type] = true;
                        }
                        
                        if (node.language) {
                            if (node.color) {
                                colors[node.language] = node.color;
                            }
                        }
                    });
                    
                    // יצירת אלמנטים למקרא
                    let html = '';
                    
                    // מקרא שפות
                    html += '<div><strong>שפות תכנות:</strong></div>';
                    Object.keys(colors).forEach(language => {
                        html += `<div class="color-item">
                            <div class="color-box" style="background-color: ${colors[language]};"></div>
                            <span>${language}</span>
                        </div>`;
                    });
                    
                    // מקרא סוגי קודקודים
                    html += '<div style="margin-top: 10px;"><strong>סוגי קודקודים:</strong></div>';
                    Object.keys(types).forEach(type => {
                        const shape = type === 'file' ? '■' : 
                                    type === 'class' ? '◆' : 
                                    type === 'function' ? '●' : 
                                    type === 'method' ? '▲' : 
                                    '●';
                        
                        html += `<div class="color-item">
                            <span style="font-size: 16px; margin-left: 5px;">${shape}</span>
                            <span>${translateType(type)}</span>
                        </div>`;
                    });
                    
                    return html;
                }
                
                // אתחול מקרא צבעים
                document.getElementById('color-legend').innerHTML = createColorLegend();
                
                // מאזיני אירועים לכפתורי שליטה
                document.getElementById('zoom-in').addEventListener('click', function() {
                    network.zoom(1.2);
                });
                
                document.getElementById('zoom-out').addEventListener('click', function() {
                    network.zoom(0.8);
                });
                
                document.getElementById('zoom-fit').addEventListener('click', function() {
                    network.fit();
                });
                
                let physicsEnabled = true;
                document.getElementById('physics-toggle').addEventListener('click', function() {
                    physicsEnabled = !physicsEnabled;
                    network.setOptions({ physics: { enabled: physicsEnabled } });
                    this.innerText = physicsEnabled ? 'פיזיקה: פעיל' : 'פיזיקה: כבוי';
                });
                </script>
            </body>
            </html>
            """
            
            return html
            
        except Exception as e:
            logger.error(f"שגיאה ביצירת ויזואליזציית HTML: {str(e)}")
            return f"<html><body><h1>שגיאה ביצירת ויזואליזציה</h1><p>{str(e)}</p></body></html>"
    
    def serialize(self) -> Dict[str, Any]:
        """
        ייצוא המצב המלא של מנהל גרף הקשרים
        
        Returns:
            מילון עם המצב המלא
        """
        # ייצוא הגרף לפורמט JSON
        graph_data = self.get_graph_json()
        
        # ייצוא הקונפיגורציה
        config_data = self.config.copy()
        
        # ייצוא מטמון
        cache_data = {
            "size": len(self._cache)
        }
        
        return {
            "graph": graph_data,
            "config": config_data,
            "cache": cache_data,
            "timestamp": time.time()
        }
    
    def deserialize(self, data: Dict[str, Any]) -> bool:
        """
        ייבוא מצב מנהל גרף הקשרים
        
        Args:
            data: מילון עם המצב
            
        Returns:
            האם הייבוא הצליח
        """
        try:
            # ייבוא הקונפיגורציה
            if "config" in data:
                self.config = data["config"]
            
            # ייבוא הגרף
            if "graph" in data:
                graph_data = data["graph"]
                
                # יצירת גרף חדש
                self.graph = nx.DiGraph()
                
                # הוספת קודקודים
                for node in graph_data.get("nodes", []):
                    node_id = node.pop("id")
                    self.graph.add_node(node_id, **node)
                
                # הוספת קשתות
                for edge in graph_data.get("edges", []):
                    source = edge.pop("source")
                    target = edge.pop("target")
                    self.graph.add_edge(source, target, **edge)
                
                # ייבוא מידע נוסף
                if "info" in graph_data:
                    self.graph_info = graph_data["info"]
            
            logger.info(f"ייבוא מצב גרף הקשרים הצליח")
            return True
            
        except Exception as e:
            logger.error(f"שגיאה בייבוא מצב גרף הקשרים: {str(e)}")
            return False
    
    def clear(self) -> None:
        """
        ניקוי הגרף ואיפוס המצב
        """
        self.graph = nx.DiGraph()
        self.graph_info = {
            "node_types": {},
            "edge_types": {},
            "metrics": {},
            "communities": [],
            "timestamps": {
                "created": time.time(),
                "updated": time.time()
            }
        }
        self._cache = {}
        
        logger.info("גרף הקשרים נוקה")

# ייבוא ספריות נוספות הדרושות לפונקציות מתקדמות
import random
