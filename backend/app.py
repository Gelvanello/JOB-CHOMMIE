import os
from flask import Flask, jsonify, request
from flask_cors import CORS
from datetime import datetime
from sqlalchemy.orm import Session
from .database import Base, engine, get_db
from .models import Job
from .scheduler import start_scheduler

app = Flask(__name__)
CORS(app)

# Create tables on startup
Base.metadata.create_all(bind=engine)

# Start background scheduler
start_scheduler()

@app.route('/')
def home():
    return {'message': 'AI Job Chommie API is running'}

@app.route('/health')
def health_check():
    """Health check endpoint for container monitoring"""
    try:
        return jsonify({
            'status': 'healthy',
            'timestamp': datetime.utcnow().isoformat(),
            'services': { 'api': 'up' },
            'version': '1.0.0'
        }), 200
    except Exception as e:
        return jsonify({ 'status': 'unhealthy', 'error': str(e), 'timestamp': datetime.utcnow().isoformat() }), 503

# Jobs search endpoint
@app.route('/api/jobs')
def list_jobs():
    q = request.args.get('q', '').lower()
    page = int(request.args.get('page', 1))
    limit = int(request.args.get('limit', 20))
    offset = (page - 1) * limit
    db: Session = next(get_db())
    query = db.query(Job)
    if q:
        query = query.filter(Job.title.ilike(f"%{q}%"))
    total = query.count()
    jobs = query.order_by(Job.created_at.desc()).offset(offset).limit(limit).all()
    items = [{
        'id': j.id,
        'title': j.title,
        'company': j.company,
        'location': j.location,
        'description': j.description,
        'url': j.url,
        'date_posted': j.date_posted
    } for j in jobs]
    return { 'data': items, 'total': total, 'page': page }


