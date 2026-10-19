import os
import re

main_path = r"c:\Users\l\AppDev\Aethenox\backend\app\main.py"
with open(main_path, 'r', encoding='utf-8') as f:
    content = f.read()

if 'from fastapi.staticfiles import StaticFiles' not in content:
    content = content.replace(
        'from fastapi import FastAPI, HTTPException',
        'from fastapi import FastAPI, HTTPException\nfrom fastapi.staticfiles import StaticFiles\nfrom fastapi.responses import FileResponse\nimport os'
    )
    
    app_run = 'if __name__ == "__main__":'
    if app_run in content:
        static_code = '''
# Mount the static web app
static_dir = os.path.join(os.path.dirname(__file__), "static")
if os.path.exists(static_dir):
    app.mount("/app", StaticFiles(directory=static_dir, html=True), name="static")

    @app.get("/")
    async def serve_spa():
        return FileResponse(os.path.join(static_dir, "index.html"))

'''
        content = content.replace(app_run, static_code + app_run)
    
    with open(main_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("main.py updated to serve static files.")
else:
    print("main.py already serves static files.")
