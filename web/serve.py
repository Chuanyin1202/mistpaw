"""Static Godot hosting with isolation headers and precompressed downloads."""
import argparse,gzip,mimetypes,json
from http.server import SimpleHTTPRequestHandler,ThreadingHTTPServer
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--diagnostics',action='store_true');p.add_argument('--root',required=True);p.add_argument('--port',type=int,default=8095);p.add_argument('--bind',default='127.0.0.1');a=p.parse_args()
class Handler(SimpleHTTPRequestHandler):
 def __init__(self,*args,**kwargs):super().__init__(*args,directory=a.root,**kwargs)
 def end_headers(self):
  self.send_header('Cross-Origin-Opener-Policy','same-origin')
  self.send_header('Cross-Origin-Embedder-Policy','require-corp')
  self.send_header('Cache-Control','no-cache')
  super().end_headers()
 def do_POST(self):
  if not a.diagnostics or self.path!='/debug/touch':self.send_error(404);return
  try:
   length=int(self.headers.get('Content-Length','0'))
   if not 0<length<=2048:raise ValueError('size')
   data=json.loads(self.rfile.read(length))
   keys={'revision','finger','point_x','point_y','strength','charge','running','speed','move_x','move_y','paused','ready','ended','attack','dash'}
   if not isinstance(data,dict):raise ValueError('payload')
   sample={k:v for k,v in data.items() if k in keys and isinstance(v,(int,float,bool,str))}
   target=Path(a.root).resolve().parent/'verification'/'phone-touch.ndjson'
   target.parent.mkdir(exist_ok=True)
   with target.open('a') as log:log.write(json.dumps(sample)+'\n')
  except (ValueError,TypeError):self.send_error(400);return
  self.send_response(204);self.end_headers()
 def list_directory(self,path):self.send_error(403);return None
 def send_head(self):
  path=Path(self.translate_path(self.path))
  compressed=Path(str(path)+'.gz')
  if 'gzip' in self.headers.get('Accept-Encoding','') and path.is_file() and compressed.is_file():
   self.send_response(200)
   self.send_header('Content-Type',mimetypes.guess_type(str(path))[0] or 'application/octet-stream')
   self.send_header('Content-Encoding','gzip')
   self.send_header('Vary','Accept-Encoding')
   self.send_header('Content-Length',str(compressed.stat().st_size))
   self.end_headers()
   return compressed.open('rb')
  return super().send_head()
ThreadingHTTPServer((a.bind,a.port),Handler).serve_forever()
