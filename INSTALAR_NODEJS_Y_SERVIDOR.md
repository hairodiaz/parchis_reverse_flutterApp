# 🚀 INSTALACIÓN DE NODE.JS Y PRUEBA DEL SERVIDOR

## 🎯 **DOS OPCIONES DE SERVIDOR:**

### **🟢 OPCIÓN A: Node.js (Recomendada)**
- Más rápido y eficiente
- Ideal para producción

### **🐍 OPCIÓN B: Python (Más fácil)**
- Python ya está instalado en Windows 11
- Más fácil de configurar

---

## 🟢 **OPCIÓN A: SERVIDOR NODE.JS**

### **Paso 1: Instalar Node.js**
1. **Ve a**: https://nodejs.org/
2. **Descarga**: La versión LTS (Long Term Support) - botón verde
3. **Ejecuta** el instalador descargado
4. **Durante instalación**: Acepta todas las opciones por defecto
5. **¡IMPORTANTE!**: Reinicia PowerShell después de instalar

### **Paso 2: Verificar instalación**
```powershell
node --version
npm --version
```

### **Paso 3: Instalar dependencias**
```powershell
cd "c:\Users\Hairo Diaz\Desktop\Proyectos\Flutter\parchis_reverse_app\websocket_server"
npm install
```

### **Paso 4: Ejecutar servidor**
```powershell
npm start
```

---

## � **OPCIÓN B: SERVIDOR PYTHON (MÁS FÁCIL)**

### **Paso 1: Verificar Python**
```powershell
python --version
```

**Si no tienes Python:**
- Descargar de: https://www.python.org/downloads/
- O instalar desde Microsoft Store: "Python 3.11"

### **Paso 2: Instalar dependencia**
```powershell
pip install websockets
```

### **Paso 3: Ejecutar servidor Python**
```powershell
cd "c:\Users\Hairo Diaz\Desktop\Proyectos\Flutter\parchis_reverse_app\websocket_server"
python server.py
```

---

## ✅ **SERVIDOR FUNCIONANDO (Cualquier opción):**

**Deberías ver:**
```
🚀 Servidor WebSocket iniciado en puerto 8080
📡 Esperando conexiones...
```

## 🧪 **PROBAR CONEXIÓN DESDE FLUTTER:**

Una vez que el servidor esté funcionando, ejecuta la app Flutter:

```bash
flutter run --debug
```

**Ve a "Salas Públicas" y deberías ver en los logs:**
```
� Auto-conectando a WebSocket...
🔌 Conectando a WebSocket: ws://localhost:8080
✅ Conectado al servidor WebSocket
```

---

**¿Con cuál opción quieres empezar? Node.js o Python?** 🚀