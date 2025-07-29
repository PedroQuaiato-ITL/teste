from flask import Flask, jsonify
from flask_cors import CORS
import psycopg2
import os
import requests

app = Flask(__name__)
CORS(app)

DB_HOST = os.environ.get('DB_HOST')
DB_USER = os.environ.get('DB_USER')
DB_PASSWORD = os.environ.get('DB_PASSWORD')
DB_NAME = os.environ.get('DB_NAME')

# Cache simples em memória
cep_cache = {}

def get_db_connection():
    return psycopg2.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASSWORD,
        dbname=DB_NAME
    )

def get_coords_from_cep(cep):
    if cep in cep_cache:
        return cep_cache[cep]

    url = f'https://nominatim.openstreetmap.org/search?format=json&country=br&postalcode={cep}'
    headers = {'User-Agent': 'PedroMapBot'}
    res = requests.get(url, headers=headers)
    data = res.json()

    if data:
        lat = float(data[0]['lat'])
        lon = float(data[0]['lon'])
        cep_cache[cep] = (lat, lon)
        return lat, lon
    else:
        return None, None

@app.route('/clientes')
def clientes():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute('SELECT uuid, revenda, cep FROM public.view_revendas')
    rows = cur.fetchall()
    cur.close()
    conn.close()

    cep_groups = {}

    for uuid, revenda, cep in rows:
        if cep not in cep_groups:
            cep_groups[cep] = {
                'revendas': [],
                'lat': None,
                'lon': None
            }
        cep_groups[cep]['revendas'].append(revenda)

    results = []
    for cep, info in cep_groups.items():
        lat, lon = get_coords_from_cep(cep)
        if lat and lon:
            results.append({
                'cep': cep,
                'nome': ', '.join(info['revendas']),
                'lat': lat,
                'lon': lon
            })

    return jsonify(results)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=3333)
