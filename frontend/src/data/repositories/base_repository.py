from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from contextlib import contextmanager

Base = declarative_base()

class BaseRepository:
    def __init__(self, session_factory):
        self.session_factory = session_factory

    @contextmanager
    def session_scope(self):
        session = self.session_factory()
        try:
            yield session
            session.commit()
        except:
            session.rollback()
            raise
        finally:
            session.close()

    def add(self, session, entity):
        session.add(entity)

    def get(self, session, model, entity_id):
        return session.query(model).get(entity_id)

    def list_all(self, session, model, skip=0, limit=100):
        return session.query(model).offset(skip).limit(limit).all()

    def delete(self, session, entity):
        session.delete(entity)