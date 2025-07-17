# Database Access Patterns Refactoring Plan

## 🔧 Current Issues Analysis

### Critical Problems Identified
1. **Direct Database Access Breaking Abstraction**
   - `job.py:111-112`: `self.db._make_request` used directly
   - `job.py:146`: Same issue in `get_trending_jobs`
   - `superbase_client.py:146`: Unsafe query construction

2. **N+1 Query Problem**
   - `superbase_client.py:226-228`: Multiple sequential queries in `get_user_applications`

3. **Duplicate Return Statement**
   - `superbase_client.py:206`: Duplicate return causing unreachable code

4. **No Repository Pattern**
   - Direct database calls scattered throughout models
   - No centralized data access layer

## 🏗️ Refactoring Implementation Plan

### Phase 1: Repository Pattern Implementation (Week 1)

#### 1.1 Create Base Repository Interface
```python
# src/repositories/base_repository.py
from abc import ABC, abstractmethod
from typing import Dict, List, Optional, Any
from datetime import datetime

class BaseRepository(ABC):
    """Base repository interface for all data access operations"""
    
    @abstractmethod
    def create(self, data: Dict) -> Dict:
        """Create a new record"""
        pass
    
    @abstractmethod
    def get_by_id(self, id: str) -> Optional[Dict]:
        """Get record by ID"""
        pass
    
    @abstractmethod
    def update(self, id: str, data: Dict) -> Dict:
        """Update record by ID"""
        pass
    
    @abstractmethod
    def delete(self, id: str) -> bool:
        """Delete record by ID"""
        pass
    
    @abstractmethod
    def list(self, filters: Optional[Dict] = None, limit: int = 50, offset: int = 0) -> List[Dict]:
        """List records with optional filtering"""
        pass

class RepositoryError(Exception):
    """Base exception for repository operations"""
    pass

class RecordNotFoundError(RepositoryError):
    """Raised when a record is not found"""
    pass

class ValidationError(RepositoryError):
    """Raised when data validation fails"""
    pass
```

#### 1.2 Implement Supabase Repository
```python
# src/repositories/supabase_repository.py
from typing import Dict, List, Optional, Any
from datetime import datetime
import logging
from .base_repository import BaseRepository, RepositoryError, RecordNotFoundError

logger = logging.getLogger(__name__)

class SupabaseRepository(BaseRepository):
    """Supabase-specific repository implementation"""
    
    def __init__(self, supabase_client, table_name: str):
        self.client = supabase_client
        self.table_name = table_name
        self.validator = None  # Will be set by subclasses
    
    def _validate_data(self, data: Dict) -> Dict:
        """Validate data before database operations"""
        if self.validator:
            if not self.validator.validate(data):
                raise ValidationError(f"Invalid data: {self.validator.errors}")
            return self.validator.document
        return data
    
    def _sanitize_filters(self, filters: Dict) -> Dict:
        """Sanitize and validate query filters"""
        if not filters:
            return {}
        
        sanitized = {}
        for key, value in filters.items():
            if isinstance(value, str):
                # Remove potentially dangerous characters
                sanitized_value = value.replace("'", "''").replace(";", "")
                sanitized[key] = sanitized_value
            else:
                sanitized[key] = value
        
        return sanitized
    
    def create(self, data: Dict) -> Dict:
        """Create a new record with validation"""
        try:
            validated_data = self._validate_data(data)
            validated_data["created_at"] = datetime.utcnow().isoformat()
            validated_data["updated_at"] = datetime.utcnow().isoformat()
            
            result = self.client._make_request("POST", self.table_name, validated_data)
            
            if not result:
                raise RepositoryError("Failed to create record")
            
            logger.info(f"Created {self.table_name} record: {result.get('id')}")
            return result
            
        except Exception as e:
            logger.error(f"Error creating {self.table_name} record: {str(e)}")
            raise RepositoryError(f"Failed to create record: {str(e)}")
    
    def get_by_id(self, id: str) -> Optional[Dict]:
        """Get record by ID with error handling"""
        try:
            result = self.client._make_request("GET", f"{self.table_name}?id=eq.{id}")
            
            if not result or not isinstance(result, list):
                return None
            
            return result[0] if result else None
            
        except Exception as e:
            logger.error(f"Error retrieving {self.table_name} record {id}: {str(e)}")
            return None
    
    def update(self, id: str, data: Dict) -> Dict:
        """Update record by ID with validation"""
        try:
            validated_data = self._validate_data(data)
            validated_data["updated_at"] = datetime.utcnow().isoformat()
            
            result = self.client._make_request("PATCH", f"{self.table_name}?id=eq.{id}", validated_data)
            
            if not result:
                raise RecordNotFoundError(f"Record {id} not found")
            
            logger.info(f"Updated {self.table_name} record: {id}")
            return result
            
        except Exception as e:
            logger.error(f"Error updating {self.table_name} record {id}: {str(e)}")
            raise RepositoryError(f"Failed to update record: {str(e)}")
    
    def delete(self, id: str) -> bool:
        """Delete record by ID"""
        try:
            result = self.client._make_request("DELETE", f"{self.table_name}?id=eq.{id}")
            
            # Supabase DELETE returns empty list if successful
            success = result is not None
            if success:
                logger.info(f"Deleted {self.table_name} record: {id}")
            
            return success
            
        except Exception as e:
            logger.error(f"Error deleting {self.table_name} record {id}: {str(e)}")
            return False
    
    def list(self, filters: Optional[Dict] = None, limit: int = 50, offset: int = 0) -> List[Dict]:
        """List records with filtering and pagination"""
        try:
            query_params = {
                "limit": limit,
                "offset": offset,
                "order": "created_at.desc"
            }
            
            if filters:
                sanitized_filters = self._sanitize_filters(filters)
                query_params.update(sanitized_filters)
            
            result = self.client._make_request("GET", self.table_name, query_params)
            
            if not isinstance(result, list):
                logger.warning(f"Unexpected result type from {self.table_name}: {type(result)}")
                return []
            
            return result
            
        except Exception as e:
            logger.error(f"Error listing {self.table_name} records: {str(e)}")
            return []
    
    def count(self, filters: Optional[Dict] = None) -> int:
        """Count records with optional filtering"""
        try:
            query_params = {"select": "id"}
            
            if filters:
                sanitized_filters = self._sanitize_filters(filters)
                query_params.update(sanitized_filters)
            
            result = self.client._make_request("GET", self.table_name, query_params)
            
            if isinstance(result, list):
                return len(result)
            return 0
            
        except Exception as e:
            logger.error(f"Error counting {self.table_name} records: {str(e)}")
            return 0
```

#### 1.3 Create Specific Repositories
```python
# src/repositories/user_repository.py
from typing import Dict, List, Optional
from .supabase_repository import SupabaseRepository
from cerberus import Validator

class UserRepository(SupabaseRepository):
    """Repository for user operations"""
    
    def __init__(self, supabase_client):
        super().__init__(supabase_client, "users")
        self.validator = Validator({
            'name': {'type': 'string', 'required': True, 'maxlength': 100},
            'email': {'type': 'string', 'required': True, 'regex': r'^[^@]+@[^@]+\.[^@]+$'},
            'subscription_plan': {'type': 'string', 'allowed': ['basic', 'premium', 'enterprise']},
            'profile_complete': {'type': 'boolean'},
            'last_login': {'type': 'string'}
        })
    
    def get_by_email(self, email: str) -> Optional[Dict]:
        """Get user by email address"""
        try:
            result = self.client._make_request("GET", f"{self.table_name}?email=eq.{email}")
            return result[0] if result and isinstance(result, list) else None
        except Exception as e:
            logger.error(f"Error retrieving user by email {email}: {str(e)}")
            return None
    
    def update_subscription(self, user_id: str, plan: str, expires_at: str = "") -> Dict:
        """Update user subscription plan"""
        update_data = {
            "subscription_plan": plan,
            "subscription_expires_at": expires_at,
            "updated_at": datetime.utcnow().isoformat()
        }
        return self.update(user_id, update_data)
    
    def get_active_users(self, days: int = 30) -> List[Dict]:
        """Get users active in the last N days"""
        from datetime import datetime, timedelta
        
        cutoff_date = (datetime.utcnow() - timedelta(days=days)).isoformat()
        filters = {"last_login": f"gte.{cutoff_date}"}
        
        return self.list(filters, limit=1000)

# src/repositories/job_repository.py
from typing import Dict, List, Optional
from .supabase_repository import SupabaseRepository
from cerberus import Validator

class JobRepository(SupabaseRepository):
    """Repository for job operations"""
    
    def __init__(self, supabase_client):
        super().__init__(supabase_client, "jobs")
        self.validator = Validator({
            'title': {'type': 'string', 'required': True, 'maxlength': 200},
            'company': {'type': 'string', 'required': True, 'maxlength': 100},
            'location': {'type': 'string', 'required': True, 'maxlength': 100},
            'description': {'type': 'string', 'required': True},
            'salary_min': {'type': 'integer', 'min': 0},
            'salary_max': {'type': 'integer', 'min': 0},
            'job_type': {'type': 'string', 'allowed': ['full-time', 'part-time', 'contract', 'internship']},
            'remote_friendly': {'type': 'boolean'},
            'is_active': {'type': 'boolean'}
        })
    
    def search_jobs(self, query: str, location: str = "", job_type: str = "", 
                   salary_min: int = None, salary_max: int = None, 
                   remote_only: bool = False, limit: int = 50) -> List[Dict]:
        """Advanced job search with multiple filters"""
        filters = {}
        
        if query:
            # Use Supabase's built-in text search
            filters["or"] = f"title.ilike.%{query}%,company.ilike.%{query}%,description.ilike.%{query}%"
        
        if location:
            filters["location"] = f"ilike.%{location}%"
        
        if job_type:
            filters["job_type"] = f"eq.{job_type}"
        
        if salary_min is not None:
            filters["salary_min"] = f"gte.{salary_min}"
        
        if salary_max is not None:
            filters["salary_max"] = f"lte.{salary_max}"
        
        if remote_only:
            filters["remote_friendly"] = "eq.true"
        
        return self.list(filters, limit=limit)
    
    def get_trending_jobs(self, days: int = 7, limit: int = 20) -> List[Dict]:
        """Get trending jobs based on application count"""
        from datetime import datetime, timedelta
        
        # Get recent jobs
        since_date = (datetime.utcnow() - timedelta(days=days)).isoformat()
        recent_jobs = self.list({"created_at": f"gte.{since_date}"}, limit=1000)
        
        # Get application counts for these jobs
        job_stats = []
        for job in recent_jobs:
            application_count = self._get_application_count(job['id'])
            job['application_count'] = application_count
            job_stats.append(job)
        
        # Sort by application count and return top results
        trending = sorted(job_stats, key=lambda x: x['application_count'], reverse=True)
        return trending[:limit]
    
    def get_similar_jobs(self, job_id: str, limit: int = 10) -> List[Dict]:
        """Get jobs similar to the given job"""
        job = self.get_by_id(job_id)
        if not job:
            return []
        
        # Extract keywords from title and description
        keywords = self._extract_keywords(job['title'] + ' ' + job['description'])
        
        # Search for jobs with similar keywords
        similar_jobs = []
        for keyword in keywords[:3]:  # Use top 3 keywords
            jobs = self.search_jobs(keyword, limit=20)
            similar_jobs.extend(jobs)
        
        # Remove duplicates and the original job
        seen_ids = set()
        unique_similar = []
        
        for job_item in similar_jobs:
            if job_item['id'] not in seen_ids and job_item['id'] != job_id:
                seen_ids.add(job_item['id'])
                unique_similar.append(job_item)
        
        return unique_similar[:limit]
    
    def _get_application_count(self, job_id: str) -> int:
        """Get application count for a job"""
        try:
            result = self.client._make_request("GET", f"applications?job_id=eq.{job_id}&select=id")
            return len(result) if isinstance(result, list) else 0
        except Exception as e:
            logger.error(f"Error getting application count for job {job_id}: {str(e)}")
            return 0
    
    def _extract_keywords(self, text: str) -> List[str]:
        """Extract keywords from text for similarity matching"""
        import re
        
        # Remove common words and extract meaningful terms
        common_words = {'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by'}
        words = re.findall(r'\b\w+\b', text.lower())
        keywords = [word for word in words if word not in common_words and len(word) > 3]
        
        # Return most common keywords
        from collections import Counter
        return [word for word, count in Counter(keywords).most_common(5)]

# src/repositories/application_repository.py
from typing import Dict, List, Optional
from .supabase_repository import SupabaseRepository
from cerberus import Validator

class ApplicationRepository(SupabaseRepository):
    """Repository for application operations"""
    
    def __init__(self, supabase_client):
        super().__init__(supabase_client, "applications")
        self.validator = Validator({
            'user_id': {'type': 'string', 'required': True},
            'job_id': {'type': 'string', 'required': True},
            'cover_letter': {'type': 'string', 'maxlength': 2000},
            'resume_url': {'type': 'string'},
            'status': {'type': 'string', 'allowed': ['pending', 'reviewed', 'interview', 'accepted', 'rejected']},
            'notes': {'type': 'string', 'maxlength': 500}
        })
    
    def get_user_applications(self, user_id: str) -> List[Dict]:
        """Get all applications for a user with job details"""
        applications = self.list({"user_id": f"eq.{user_id}"}, limit=1000)
        
        # Enrich with job details in a single query to avoid N+1
        if applications:
            job_ids = [app['job_id'] for app in applications]
            jobs = self._get_jobs_by_ids(job_ids)
            
            # Create job lookup dictionary
            job_lookup = {job['id']: job for job in jobs}
            
            # Add job details to applications
            for app in applications:
                app['job_details'] = job_lookup.get(app['job_id'], {})
        
        return applications
    
    def get_job_applications(self, job_id: str) -> List[Dict]:
        """Get all applications for a job with user details"""
        applications = self.list({"job_id": f"eq.{job_id}"}, limit=1000)
        
        # Enrich with user details
        if applications:
            user_ids = [app['user_id'] for app in applications]
            users = self._get_users_by_ids(user_ids)
            
            # Create user lookup dictionary
            user_lookup = {user['id']: user for user in users}
            
            # Add user details to applications
            for app in applications:
                app['user_details'] = user_lookup.get(app['user_id'], {})
        
        return applications
    
    def update_status(self, application_id: str, status: str, notes: str = "") -> Dict:
        """Update application status"""
        update_data = {
            "status": status,
            "notes": notes,
            "updated_at": datetime.utcnow().isoformat()
        }
        return self.update(application_id, update_data)
    
    def _get_jobs_by_ids(self, job_ids: List[str]) -> List[Dict]:
        """Get multiple jobs by IDs in a single query"""
        if not job_ids:
            return []
        
        # Create OR condition for multiple IDs
        id_conditions = ",".join([f"eq.{job_id}" for job_id in job_ids])
        try:
            result = self.client._make_request("GET", f"jobs?id=in.({id_conditions})")
            return result if isinstance(result, list) else []
        except Exception as e:
            logger.error(f"Error getting jobs by IDs: {str(e)}")
            return []
    
    def _get_users_by_ids(self, user_ids: List[str]) -> List[Dict]:
        """Get multiple users by IDs in a single query"""
        if not user_ids:
            return []
        
        # Create OR condition for multiple IDs
        id_conditions = ",".join([f"eq.{user_id}" for user_id in user_ids])
        try:
            result = self.client._make_request("GET", f"users?id=in.({id_conditions})")
            return result if isinstance(result, list) else []
        except Exception as e:
            logger.error(f"Error getting users by IDs: {str(e)}")
            return []
```

### Phase 2: Model Refactoring (Week 2)

#### 2.1 Refactor Job Model
```python
# src/models/job.py (Refactored)
from typing import Dict, List, Optional
from datetime import datetime, timedelta
import re
from ..repositories.job_repository import JobRepository

class Job:
    """Job model with repository pattern"""
    
    def __init__(self, supabase_client=None):
        self.repository = JobRepository(supabase_client)
    
    def create(self, title: str, company: str, location: str, description: str, **kwargs) -> Dict:
        """Create a new job with validation"""
        job_data = {
            "title": title,
            "company": company,
            "location": location,
            "description": description,
            **kwargs
        }
        
        return self.repository.create(job_data)
    
    def get_by_id(self, job_id: str) -> Optional[Dict]:
        """Get job by ID"""
        return self.repository.get_by_id(job_id)
    
    def search(self, query: str = None, location: str = None, job_type: str = None,
              salary_min: int = None, salary_max: int = None, remote_only: bool = False,
              limit: int = 50, offset: int = 0) -> List[Dict]:
        """Search jobs with multiple filters"""
        return self.repository.search_jobs(
            query=query,
            location=location,
            job_type=job_type,
            salary_min=salary_min,
            salary_max=salary_max,
            remote_only=remote_only,
            limit=limit
        )
    
    def get_latest(self, limit: int = 50) -> List[Dict]:
        """Get latest jobs"""
        return self.repository.list(limit=limit)
    
    def get_by_company(self, company: str, limit: int = 20) -> List[Dict]:
        """Get jobs by company"""
        return self.repository.list({"company": f"ilike.%{company}%"}, limit=limit)
    
    def update(self, job_id: str, **kwargs) -> Dict:
        """Update job"""
        return self.repository.update(job_id, kwargs)
    
    def delete(self, job_id: str) -> Dict:
        """Delete job"""
        success = self.repository.delete(job_id)
        return {"success": success}
    
    def get_trending_jobs(self, days: int = 7, limit: int = 20) -> List[Dict]:
        """Get trending jobs - now using repository pattern"""
        return self.repository.get_trending_jobs(days, limit)
    
    def get_similar_jobs(self, job_id: str, limit: int = 10) -> List[Dict]:
        """Get similar jobs - now using repository pattern"""
        return self.repository.get_similar_jobs(job_id, limit)
    
    def scrape_and_save_jobs(self, query: str, location: str = "South Africa", 
                            max_jobs_per_source: int = 20) -> Dict:
        """Scrape jobs from external sources and save to database"""
        try:
            # Use repository pattern for database operations
            scraped_jobs = self.scraper.scrape_all_sources(query, location, max_jobs_per_source)
            
            saved_jobs = []
            skipped_jobs = []
            
            for job_data in scraped_jobs:
                # Check if job already exists using repository
                existing_jobs = self.repository.list({
                    "title": f"eq.{job_data['title']}",
                    "company": f"eq.{job_data['company']}"
                })
                
                if existing_jobs:
                    skipped_jobs.append(job_data)
                    continue
                
                # Enhance job data
                enhanced_job = self._enhance_job_data(job_data)
                
                # Save to database using repository
                saved_job = self.repository.create(enhanced_job)
                if saved_job:
                    saved_jobs.append(saved_job)
            
            return {
                'success': True,
                'scraped_count': len(scraped_jobs),
                'saved_count': len(saved_jobs),
                'skipped_count': len(skipped_jobs),
                'saved_jobs': saved_jobs
            }
            
        except Exception as e:
            return {
                'success': False,
                'error': str(e),
                'scraped_count': 0,
                'saved_count': 0
            }
    
    # ... rest of the methods remain the same but use repository pattern
```

#### 2.2 Refactor User Model
```python
# src/models/user.py (Refactored)
from typing import Dict, List, Optional
from datetime import datetime
from ..repositories.user_repository import UserRepository

class User:
    """User model with repository pattern"""
    
    def __init__(self, supabase_client=None):
        self.repository = UserRepository(supabase_client)
    
    def create(self, name: str, email: str, password: str, **kwargs) -> Dict:
        """Create a new user with validation"""
        from ..utils.password_validator import PasswordValidator
        
        # Validate password
        validator = PasswordValidator()
        is_valid, message = validator.validate_password(password)
        if not is_valid:
            return {"success": False, "error": message}
        
        # Hash password
        hashed_password = validator.hash_password(password)
        
        user_data = {
            "name": name,
            "email": email,
            "password_hash": hashed_password,
            **kwargs
        }
        
        try:
            result = self.repository.create(user_data)
            return {"success": True, "user_id": result["id"]}
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    def get_by_id(self, user_id: str) -> Optional[Dict]:
        """Get user by ID"""
        return self.repository.get_by_id(user_id)
    
    def get_by_email(self, email: str) -> Optional[Dict]:
        """Get user by email"""
        return self.repository.get_by_email(email)
    
    def update(self, user_id: str, **kwargs) -> Dict:
        """Update user"""
        return self.repository.update(user_id, kwargs)
    
    def delete(self, user_id: str) -> Dict:
        """Delete user"""
        success = self.repository.delete(user_id)
        return {"success": success}
    
    def verify_password(self, email: str, password: str) -> bool:
        """Verify user password"""
        from ..utils.password_validator import PasswordValidator
        
        user = self.get_by_email(email)
        if not user:
            return False
        
        validator = PasswordValidator()
        return validator.verify_password(password, user.get("password_hash", ""))
    
    def update_subscription(self, user_id: str, plan: str, expires_at: str = "") -> Dict:
        """Update user subscription"""
        return self.repository.update_subscription(user_id, plan, expires_at)
```

### Phase 3: Service Layer Implementation (Week 3)

#### 3.1 Create Service Layer
```python
# src/services/job_service.py
from typing import Dict, List, Optional
from ..repositories.job_repository import JobRepository
from ..repositories.application_repository import ApplicationRepository
from ..utils.job_enhancer import JobEnhancer

class JobService:
    """Service layer for job operations"""
    
    def __init__(self, supabase_client=None):
        self.job_repository = JobRepository(supabase_client)
        self.application_repository = ApplicationRepository(supabase_client)
        self.enhancer = JobEnhancer()
    
    def search_jobs(self, search_params: Dict) -> Dict:
        """Search jobs with enhanced functionality"""
        try:
            # Validate search parameters
            validated_params = self._validate_search_params(search_params)
            
            # Perform search
            jobs = self.job_repository.search_jobs(**validated_params)
            
            # Enhance job data
            enhanced_jobs = []
            for job in jobs:
                enhanced_job = self.enhancer.enhance_job(job)
                enhanced_jobs.append(enhanced_job)
            
            return {
                "success": True,
                "jobs": enhanced_jobs,
                "total": len(enhanced_jobs),
                "filters_applied": validated_params
            }
            
        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "jobs": [],
                "total": 0
            }
    
    def get_job_details(self, job_id: str, user_id: Optional[str] = None) -> Dict:
        """Get detailed job information"""
        try:
            job = self.job_repository.get_by_id(job_id)
            if not job:
                return {"success": False, "error": "Job not found"}
            
            # Enhance job data
            enhanced_job = self.enhancer.enhance_job(job)
            
            # Get similar jobs
            similar_jobs = self.job_repository.get_similar_jobs(job_id, limit=5)
            
            # Check if user has applied
            has_applied = False
            if user_id:
                applications = self.application_repository.list({
                    "user_id": f"eq.{user_id}",
                    "job_id": f"eq.{job_id}"
                })
                has_applied = len(applications) > 0
            
            return {
                "success": True,
                "job": enhanced_job,
                "similar_jobs": similar_jobs,
                "has_applied": has_applied
            }
            
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    def get_trending_jobs(self, days: int = 7, limit: int = 20) -> Dict:
        """Get trending jobs with enhanced data"""
        try:
            trending_jobs = self.job_repository.get_trending_jobs(days, limit)
            
            # Enhance job data
            enhanced_jobs = []
            for job in trending_jobs:
                enhanced_job = self.enhancer.enhance_job(job)
                enhanced_jobs.append(enhanced_job)
            
            return {
                "success": True,
                "jobs": enhanced_jobs,
                "period_days": days
            }
            
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    def _validate_search_params(self, params: Dict) -> Dict:
        """Validate and sanitize search parameters"""
        validated = {}
        
        if "query" in params and params["query"]:
            validated["query"] = params["query"][:100]  # Limit length
        
        if "location" in params and params["location"]:
            validated["location"] = params["location"][:50]
        
        if "job_type" in params and params["job_type"]:
            valid_types = ["full-time", "part-time", "contract", "internship"]
            if params["job_type"] in valid_types:
                validated["job_type"] = params["job_type"]
        
        if "salary_min" in params and params["salary_min"]:
            try:
                salary_min = int(params["salary_min"])
                if 0 <= salary_min <= 1000000:
                    validated["salary_min"] = salary_min
            except ValueError:
                pass
        
        if "salary_max" in params and params["salary_max"]:
            try:
                salary_max = int(params["salary_max"])
                if 0 <= salary_max <= 1000000:
                    validated["salary_max"] = salary_max
            except ValueError:
                pass
        
        if "remote_only" in params:
            validated["remote_only"] = bool(params["remote_only"])
        
        validated["limit"] = min(int(params.get("limit", 50)), 100)  # Max 100
        
        return validated

# src/services/user_service.py
from typing import Dict, List, Optional
from ..repositories.user_repository import UserRepository
from ..repositories.application_repository import ApplicationRepository
from ..utils.password_validator import PasswordValidator

class UserService:
    """Service layer for user operations"""
    
    def __init__(self, supabase_client=None):
        self.user_repository = UserRepository(supabase_client)
        self.application_repository = ApplicationRepository(supabase_client)
        self.password_validator = PasswordValidator()
    
    def register_user(self, user_data: Dict) -> Dict:
        """Register a new user with validation"""
        try:
            # Validate required fields
            required_fields = ["name", "email", "password"]
            for field in required_fields:
                if field not in user_data or not user_data[field]:
                    return {"success": False, "error": f"Missing required field: {field}"}
            
            # Validate email format
            if not self._is_valid_email(user_data["email"]):
                return {"success": False, "error": "Invalid email format"}
            
            # Check if email already exists
            existing_user = self.user_repository.get_by_email(user_data["email"])
            if existing_user:
                return {"success": False, "error": "Email already registered"}
            
            # Validate password strength
            is_valid, message = self.password_validator.validate_password(user_data["password"])
            if not is_valid:
                return {"success": False, "error": message}
            
            # Create user
            result = self.user_repository.create(user_data)
            
            return {
                "success": True,
                "user_id": result["id"],
                "message": "User registered successfully"
            }
            
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    def authenticate_user(self, email: str, password: str) -> Dict:
        """Authenticate user login"""
        try:
            user = self.user_repository.get_by_email(email)
            if not user:
                return {"success": False, "error": "Invalid credentials"}
            
            # Verify password
            if not self.password_validator.verify_password(password, user.get("password_hash", "")):
                return {"success": False, "error": "Invalid credentials"}
            
            # Update last login
            self.user_repository.update(user["id"], {"last_login": datetime.utcnow().isoformat()})
            
            return {
                "success": True,
                "user": {
                    "id": user["id"],
                    "name": user["name"],
                    "email": user["email"],
                    "subscription_plan": user.get("subscription_plan", "basic")
                }
            }
            
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    def get_user_profile(self, user_id: str) -> Dict:
        """Get user profile with statistics"""
        try:
            user = self.user_repository.get_by_id(user_id)
            if not user:
                return {"success": False, "error": "User not found"}
            
            # Get user applications
            applications = self.application_repository.get_user_applications(user_id)
            
            # Calculate statistics
            stats = {
                "total_applications": len(applications),
                "pending_applications": len([a for a in applications if a["status"] == "pending"]),
                "accepted_applications": len([a for a in applications if a["status"] == "accepted"]),
                "rejected_applications": len([a for a in applications if a["status"] == "rejected"]),
                "interview_applications": len([a for a in applications if a["status"] == "interview"])
            }
            
            return {
                "success": True,
                "user": user,
                "applications": applications,
                "statistics": stats
            }
            
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    def _is_valid_email(self, email: str) -> bool:
        """Validate email format"""
        import re
        pattern = r'^[^@]+@[^@]+\.[^@]+$'
        return bool(re.match(pattern, email))
```

### Phase 4: Performance Optimization (Week 4)

#### 4.1 Implement Caching Layer
```python
# src/utils/cache_manager.py
import redis
import json
from typing import Any, Optional
from datetime import datetime, timedelta

class CacheManager:
    """Redis-based cache manager"""
    
    def __init__(self, redis_url: str = "redis://localhost:6379"):
        self.redis_client = redis.from_url(redis_url)
        self.default_ttl = 3600  # 1 hour
    
    def get(self, key: str) -> Optional[Any]:
        """Get value from cache"""
        try:
            value = self.redis_client.get(key)
            return json.loads(value) if value else None
        except Exception as e:
            print(f"Cache get error: {e}")
            return None
    
    def set(self, key: str, value: Any, ttl: int = None) -> bool:
        """Set value in cache"""
        try:
            ttl = ttl or self.default_ttl
            serialized_value = json.dumps(value)
            return self.redis_client.setex(key, ttl, serialized_value)
        except Exception as e:
            print(f"Cache set error: {e}")
            return False
    
    def delete(self, key: str) -> bool:
        """Delete value from cache"""
        try:
            return bool(self.redis_client.delete(key))
        except Exception as e:
            print(f"Cache delete error: {e}")
            return False
    
    def invalidate_pattern(self, pattern: str) -> int:
        """Invalidate all keys matching pattern"""
        try:
            keys = self.redis_client.keys(pattern)
            if keys:
                return self.redis_client.delete(*keys)
            return 0
        except Exception as e:
            print(f"Cache invalidate error: {e}")
            return 0

# Enhanced repositories with caching
class CachedJobRepository(JobRepository):
    """Job repository with caching"""
    
    def __init__(self, supabase_client, cache_manager):
        super().__init__(supabase_client)
        self.cache = cache_manager
    
    def get_by_id(self, id: str) -> Optional[Dict]:
        """Get job by ID with caching"""
        cache_key = f"job:{id}"
        cached_job = self.cache.get(cache_key)
        
        if cached_job:
            return cached_job
        
        job = super().get_by_id(id)
        if job:
            self.cache.set(cache_key, job, ttl=1800)  # 30 minutes
        
        return job
    
    def search_jobs(self, query: str = None, location: str = None, job_type: str = None,
                   salary_min: int = None, salary_max: int = None, 
                   remote_only: bool = False, limit: int = 50) -> List[Dict]:
        """Search jobs with caching"""
        # Create cache key based on search parameters
        cache_key = f"job_search:{hash(frozenset(locals().items()))}"
        cached_results = self.cache.get(cache_key)
        
        if cached_results:
            return cached_results
        
        results = super().search_jobs(
            query=query, location=location, job_type=job_type,
            salary_min=salary_min, salary_max=salary_max,
            remote_only=remote_only, limit=limit
        )
        
        # Cache results for 15 minutes
        self.cache.set(cache_key, results, ttl=900)
        
        return results
```

#### 4.2 Implement Connection Pooling
```python
# src/utils/database_pool.py
import psycopg2
from psycopg2 import pool
from contextlib import contextmanager
import logging

logger = logging.getLogger(__name__)

class DatabasePool:
    """Database connection pool manager"""
    
    def __init__(self, min_conn=1, max_conn=20, **kwargs):
        self.pool = pool.ThreadedConnectionPool(
            min_conn, max_conn,
            **kwargs
        )
    
    @contextmanager
    def get_connection(self):
        """Get database connection from pool"""
        conn = None
        try:
            conn = self.pool.getconn()
            yield conn
        except Exception as e:
            logger.error(f"Database connection error: {e}")
            if conn:
                conn.rollback()
            raise
        finally:
            if conn:
                self.pool.putconn(conn)
    
    def close(self):
        """Close all connections in pool"""
        if self.pool:
            self.pool.closeall()

# Enhanced Supabase client with connection pooling
class PooledSupabaseClient:
    """Supabase client with connection pooling"""
    
    def __init__(self, supabase_url: str, supabase_key: str, pool_config: dict = None):
        self.supabase_url = supabase_url
        self.supabase_key = supabase_key
        self.pool_config = pool_config or {
            "min_conn": 5,
            "max_conn": 20
        }
        self.db_pool = None  # Initialize when needed
    
    def _get_db_pool(self):
        """Get database connection pool"""
        if not self.db_pool:
            self.db_pool = DatabasePool(**self.pool_config)
        return self.db_pool
```

## 📊 Migration Strategy

### Phase 1: Gradual Migration (Week 1-2)
1. **Create new repository classes** alongside existing code
2. **Implement service layer** for new features
3. **Add caching** to frequently accessed data
4. **Test new patterns** with existing functionality

### Phase 2: Parallel Implementation (Week 3-4)
1. **Run old and new patterns in parallel**
2. **Compare performance** and results
3. **Gradually migrate** endpoints to new patterns
4. **Monitor for issues** and rollback if needed

### Phase 3: Complete Migration (Week 5-6)
1. **Remove old direct database access**
2. **Update all models** to use repository pattern
3. **Implement comprehensive caching**
4. **Performance testing** and optimization

## 🎯 Success Metrics

### Performance Improvements
- **Query Response Time**: 50% reduction in average query time
- **Database Connections**: 80% reduction in connection overhead
- **Cache Hit Rate**: >80% for frequently accessed data
- **Memory Usage**: 30% reduction in memory footprint

### Code Quality Improvements
- **Test Coverage**: >90% for repository layer
- **Code Duplication**: 70% reduction in duplicate database code
- **Error Handling**: 100% of database operations have proper error handling
- **Type Safety**: 100% type hints for all repository methods

### Security Improvements
- **SQL Injection**: 100% prevention through parameterized queries
- **Input Validation**: 100% of user inputs validated
- **Error Information**: No sensitive data leaked in error messages
- **Access Control**: Proper abstraction of database access

## 📋 Implementation Checklist

### Repository Pattern
- [ ] Create base repository interface
- [ ] Implement Supabase repository
- [ ] Create specific repositories (User, Job, Application)
- [ ] Add input validation and sanitization
- [ ] Implement proper error handling

### Service Layer
- [ ] Create job service
- [ ] Create user service
- [ ] Create application service
- [ ] Add business logic validation
- [ ] Implement transaction management

### Performance Optimization
- [ ] Implement Redis caching
- [ ] Add connection pooling
- [ ] Optimize N+1 queries
- [ ] Add database indexing
- [ ] Implement query result caching

### Testing & Validation
- [ ] Unit tests for all repositories
- [ ] Integration tests for service layer
- [ ] Performance benchmarks
- [ ] Security testing
- [ ] Migration testing

This comprehensive refactoring plan will transform the database access patterns from direct, unsafe calls to a robust, secure, and performant repository pattern with proper abstraction layers. 