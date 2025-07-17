from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
from .database import Base

class User(Base):
    __tablename__ = 'users'
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=False)
    first_name = Column(String)
    last_name = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)

    applications = relationship("Application", back_populates="user")
    subscriptions = relationship("Subscription", back_populates="user")

class Job(Base):
    __tablename__ = 'jobs'
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    company = Column(String)
    location = Column(String)
    description = Column(Text)
    url = Column(String)
    date_posted = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)

    applications = relationship("Application", back_populates="job")

class Application(Base):
    __tablename__ = 'applications'
    id = Column(Integer, primary_key=True, index=True)
    status = Column(String, default='Applied')
    applied_at = Column(DateTime, default=datetime.utcnow)
    user_id = Column(Integer, ForeignKey('users.id'))
    job_id = Column(Integer, ForeignKey('jobs.id'))

    user = relationship("User", back_populates="applications")
    job = relationship("Job", back_populates="applications")

class Subscription(Base):
    __tablename__ = 'subscriptions'
    id = Column(Integer, primary_key=True, index=True)
    plan_type = Column(String, default='Free')
    status = Column(String, default='Active')
    start_date = Column(DateTime, default=datetime.utcnow)
    end_date = Column(DateTime)
    user_id = Column(Integer, ForeignKey('users.id'))

    user = relationship("User", back_populates="subscriptions")
    payments = relationship("Payment", back_populates="subscription")

class Payment(Base):
    __tablename__ = 'payments'
    id = Column(Integer, primary_key=True, index=True)
    amount = Column(Integer)
    currency = Column(String, default='USD')
    status = Column(String)
    transaction_id = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)
    subscription_id = Column(Integer, ForeignKey('subscriptions.id'))

    subscription = relationship("Subscription", back_populates="payments")

class ScheduledRun(Base):
    __tablename__ = 'scheduled_runs'
    id = Column(Integer, primary_key=True, index=True)
    run_time = Column(DateTime, default=datetime.utcnow)
    api_calls_made = Column(Integer, default=0)
    success = Column(Integer, default=1)  # 1=True, 0=False
