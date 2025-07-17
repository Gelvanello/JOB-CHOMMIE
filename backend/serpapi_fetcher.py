import os, logging, requests, datetime
from sqlalchemy.orm import Session
from .models import Job, ScheduledRun

SERPAPI_KEY = os.getenv('SERPAPI_KEY')
SEARCH_QUERY = os.getenv('JOB_SEARCH_QUERY', 'software developer jobs south africa')

logger = logging.getLogger(__name__)
SERP_URL = 'https://serpapi.com/search.json'

def fetch_and_store_jobs(db: Session):
    if not SERPAPI_KEY:
        logger.warning('SERPAPI_KEY not set; skipping fetch')
        return
    params = {
        'engine': 'google_jobs',
        'q': SEARCH_QUERY,
        'api_key': SERPAPI_KEY,
        'num': 100
    }
    r = requests.get(SERP_URL, params=params, timeout=30)
    data = r.json()
    results = data.get('jobs_results', [])
    saved = 0
    for job in results:
        exists = db.query(Job).filter_by(
            title=job.get('title'), company=job.get('company_name'), location=job.get('location')
        ).first()
        if exists:
            continue
        j = Job(
            title=job.get('title'),
            company=job.get('company_name'),
            location=job.get('location'),
            description=job.get('description'),
            url=job.get('detected_extensions', {}).get('link'),
            date_posted=job.get('published_at')
        )
        db.add(j)
        saved += 1
    run = ScheduledRun(run_time=datetime.datetime.utcnow(), api_calls_made=1, success=1)
    db.add(run)
    db.commit()
    logger.info('Saved %s new jobs', saved)
