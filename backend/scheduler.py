from apscheduler.schedulers.background import BackgroundScheduler
from .database import SessionLocal
from .serpapi_fetcher import fetch_and_store_jobs
import logging

logger = logging.getLogger(__name__)
scheduler = BackgroundScheduler(timezone='UTC')

def serpapi_job():
    db = SessionLocal()
    try:
        fetch_and_store_jobs(db)
    finally:
        db.close()

# Schedule at 00:00 and 12:00 UTC every day
scheduler.add_job(serpapi_job, 'cron', hour='0,12', minute=0, id='serpapi_fetch')

def start_scheduler():
    logger.info('Starting APScheduler...')
    scheduler.start()
