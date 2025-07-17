# Security Implementation Plan for AI Job Chommie

## 🔴 Critical Security Issues & Solutions

### 1. **Exposed API Keys in Documentation**

#### Issue
- SerpAPI key potentially exposed in documentation
- Hardcoded credentials in configuration files

#### Implementation Plan

**Phase 1: Immediate Actions (Day 1)**
```bash
# 1. Remove any hardcoded keys from documentation
# 2. Create secure environment template
# 3. Update all configuration files
```

**Phase 2: Environment Security (Day 2-3)**
```python
# Create secure environment management
import os
from cryptography.fernet import Fernet
from base64 import b64encode, b64decode

class SecureConfig:
    def __init__(self):
        self.key = os.environ.get('ENCRYPTION_KEY') or Fernet.generate_key()
        self.cipher = Fernet(self.key)
    
    def encrypt_secret(self, secret: str) -> str:
        return b64encode(self.cipher.encrypt(secret.encode())).decode()
    
    def decrypt_secret(self, encrypted_secret: str) -> str:
        return self.cipher.decrypt(b64decode(encrypted_secret.encode())).decode()

# Usage in config.py
config = SecureConfig()
SERPAPI_KEY = config.decrypt_secret(os.environ.get('ENCRYPTED_SERPAPI_KEY'))
```

**Phase 3: Key Rotation Strategy (Week 1)**
```python
# Implement automatic key rotation
class KeyManager:
    def __init__(self):
        self.rotation_interval = 30  # days
        self.last_rotation = None
    
    def should_rotate(self) -> bool:
        if not self.last_rotation:
            return True
        days_since = (datetime.now() - self.last_rotation).days
        return days_since >= self.rotation_interval
    
    def rotate_keys(self):
        # Generate new keys
        # Update environment variables
        # Notify administrators
        pass
```

### 2. **Frontend Token Storage Security**

#### Issue
- Tokens stored in localStorage (vulnerable to XSS)
- No token expiration handling
- No secure token refresh mechanism

#### Implementation Plan

**Phase 1: Secure Token Storage (Day 1-2)**
```javascript
// Replace localStorage with httpOnly cookies
// Create secureStorage.js
class SecureStorage {
    static setToken(token, expiresIn = 3600) {
        // Use httpOnly cookies instead of localStorage
        document.cookie = `auth_token=${token}; path=/; max-age=${expiresIn}; secure; samesite=strict`;
    }
    
    static getToken() {
        const cookies = document.cookie.split(';');
        const tokenCookie = cookies.find(cookie => cookie.trim().startsWith('auth_token='));
        return tokenCookie ? tokenCookie.split('=')[1] : null;
    }
    
    static removeToken() {
        document.cookie = 'auth_token=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT';
    }
}

// Update api.js
import { SecureStorage } from './secureStorage.js';

api.interceptors.request.use(
    async (config) => {
        const token = SecureStorage.getToken();
        if (token) {
            config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
    },
    (error) => Promise.reject(error)
);
```

**Phase 2: Token Refresh Mechanism (Day 3-4)**
```javascript
// Implement automatic token refresh
class TokenManager {
    static async refreshToken() {
        try {
            const response = await api.post('/auth/refresh');
            if (response.data.token) {
                SecureStorage.setToken(response.data.token);
                return response.data.token;
            }
        } catch (error) {
            // Redirect to login
            window.location.href = '/login';
        }
    }
    
    static async handleTokenExpiry() {
        const token = SecureStorage.getToken();
        if (!token) {
            window.location.href = '/login';
            return;
        }
        
        // Check if token is about to expire
        const payload = JSON.parse(atob(token.split('.')[1]));
        const expiryTime = payload.exp * 1000;
        const currentTime = Date.now();
        
        if (expiryTime - currentTime < 300000) { // 5 minutes
            await this.refreshToken();
        }
    }
}
```

### 3. **SQL Injection Prevention**

#### Issue
- Direct database query construction in `superbase_client.py:146`
- Unsanitized user input in database queries

#### Implementation Plan

**Phase 1: Input Validation (Day 1-2)**
```python
# Create input validation module
import re
from typing import Any, Dict, List
from cerberus import Validator

class InputValidator:
    def __init__(self):
        self.validator = Validator()
    
    def sanitize_search_query(self, query: str) -> str:
        """Sanitize search queries to prevent injection"""
        if not query:
            return ""
        
        # Remove potentially dangerous characters
        sanitized = re.sub(r'[<>"\']', '', query)
        # Limit length
        return sanitized[:100]
    
    def validate_job_filters(self, filters: Dict) -> Dict:
        """Validate job search filters"""
        schema = {
            'search': {'type': 'string', 'maxlength': 100},
            'location': {'type': 'string', 'maxlength': 50},
            'job_type': {'type': 'string', 'allowed': ['full-time', 'part-time', 'contract', 'internship']},
            'salary_min': {'type': 'integer', 'min': 0, 'max': 1000000},
            'salary_max': {'type': 'integer', 'min': 0, 'max': 1000000},
        }
        
        if self.validator.validate(filters, schema):
            return self.validator.document
        else:
            raise ValueError(f"Invalid filters: {self.validator.errors}")
```

**Phase 2: Parameterized Queries (Day 3-4)**
```python
# Update superbase_client.py to use parameterized queries
class SecureSupabaseClient:
    def __init__(self):
        self.validator = InputValidator()
    
    def get_jobs(self, filters: Optional[Dict] = None, limit: int = 50) -> List[Dict]:
        """Secure job retrieval with parameterized queries"""
        if filters:
            # Validate and sanitize filters
            validated_filters = self.validator.validate_job_filters(filters)
            
            # Build safe query parameters
            query_params = {}
            for key, value in validated_filters.items():
                if key == "search":
                    sanitized_value = self.validator.sanitize_search_query(value)
                    query_params["or"] = f"title.ilike.%{sanitized_value}%,company.ilike.%{sanitized_value}%"
                elif key == "location":
                    sanitized_value = self.validator.sanitize_search_query(value)
                    query_params["location"] = f"ilike.%{sanitized_value}%"
                # ... other filters
        
        return self._make_request("GET", "jobs", query_params)
```

### 4. **Rate Limiting Implementation**

#### Issue
- No rate limiting on API endpoints
- Vulnerable to brute force attacks

#### Implementation Plan

**Phase 1: Basic Rate Limiting (Day 1-2)**
```python
# Implement rate limiting with Flask-Limiter
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

limiter = Limiter(
    app,
    key_func=get_remote_address,
    default_limits=["200 per day", "50 per hour"]
)

# Apply to sensitive endpoints
@app.route('/api/auth/login', methods=['POST'])
@limiter.limit("5 per minute")
def login():
    # Login logic
    pass

@app.route('/api/jobs/search', methods=['POST'])
@limiter.limit("30 per minute")
def search_jobs():
    # Search logic
    pass
```

**Phase 2: Advanced Rate Limiting (Day 3-4)**
```python
# Implement IP-based and user-based rate limiting
class AdvancedRateLimiter:
    def __init__(self):
        self.redis_client = redis.Redis()
    
    def check_rate_limit(self, user_id: str, action: str, limit: int, window: int):
        """Check rate limit for specific user and action"""
        key = f"rate_limit:{user_id}:{action}"
        current = self.redis_client.get(key)
        
        if current and int(current) >= limit:
            return False
        
        pipe = self.redis_client.pipeline()
        pipe.incr(key)
        pipe.expire(key, window)
        pipe.execute()
        return True
    
    def is_suspicious_activity(self, ip_address: str) -> bool:
        """Detect suspicious activity patterns"""
        failed_logins = self.redis_client.get(f"failed_logins:{ip_address}")
        return failed_logins and int(failed_logins) > 10
```

### 5. **CORS and Security Headers**

#### Issue
- Missing security headers
- Inadequate CORS configuration

#### Implementation Plan

**Phase 1: Security Headers (Day 1)**
```python
# Implement security headers with Flask-Talisman
from flask_talisman import Talisman

# Configure security headers
talisman = Talisman(
    app,
    content_security_policy={
        'default-src': "'self'",
        'script-src': "'self' 'unsafe-inline'",
        'style-src': "'self' 'unsafe-inline'",
        'img-src': "'self' data: https:",
        'font-src': "'self' https:",
    },
    force_https=False  # Set to True in production
)

# Custom security headers
@app.after_request
def add_security_headers(response):
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['X-Frame-Options'] = 'DENY'
    response.headers['X-XSS-Protection'] = '1; mode=block'
    response.headers['Referrer-Policy'] = 'strict-origin-when-cross-origin'
    return response
```

**Phase 2: CORS Configuration (Day 2)**
```python
# Configure CORS properly
from flask_cors import CORS

# Development CORS
if app.config['ENV'] == 'development':
    CORS(app, origins=['http://localhost:3000'], supports_credentials=True)
else:
    # Production CORS
    CORS(app, 
         origins=['https://yourdomain.com'],
         supports_credentials=True,
         methods=['GET', 'POST', 'PUT', 'DELETE'],
         allow_headers=['Content-Type', 'Authorization'])
```

### 6. **Authentication Security**

#### Issue
- Weak password requirements
- No account lockout mechanism
- Missing 2FA support

#### Implementation Plan

**Phase 1: Password Security (Day 1-2)**
```python
import re
import bcrypt

class PasswordValidator:
    def __init__(self):
        self.min_length = 8
        self.require_uppercase = True
        self.require_lowercase = True
        self.require_digits = True
        self.require_special = True
    
    def validate_password(self, password: str) -> tuple[bool, str]:
        """Validate password strength"""
        if len(password) < self.min_length:
            return False, f"Password must be at least {self.min_length} characters"
        
        if self.require_uppercase and not re.search(r'[A-Z]', password):
            return False, "Password must contain at least one uppercase letter"
        
        if self.require_lowercase and not re.search(r'[a-z]', password):
            return False, "Password must contain at least one lowercase letter"
        
        if self.require_digits and not re.search(r'\d', password):
            return False, "Password must contain at least one digit"
        
        if self.require_special and not re.search(r'[!@#$%^&*(),.?":{}|<>]', password):
            return False, "Password must contain at least one special character"
        
        return True, "Password is strong"
    
    def hash_password(self, password: str) -> str:
        """Hash password with bcrypt"""
        salt = bcrypt.gensalt()
        return bcrypt.hashpw(password.encode('utf-8'), salt).decode('utf-8')
    
    def verify_password(self, password: str, hashed: str) -> bool:
        """Verify password against hash"""
        return bcrypt.checkpw(password.encode('utf-8'), hashed.encode('utf-8'))
```

**Phase 2: Account Lockout (Day 3-4)**
```python
class AccountLockout:
    def __init__(self):
        self.redis_client = redis.Redis()
        self.max_attempts = 5
        self.lockout_duration = 900  # 15 minutes
    
    def record_failed_login(self, email: str, ip_address: str):
        """Record failed login attempt"""
        key = f"failed_login:{email}:{ip_address}"
        attempts = self.redis_client.incr(key)
        self.redis_client.expire(key, self.lockout_duration)
        
        if attempts >= self.max_attempts:
            self.lock_account(email)
    
    def is_account_locked(self, email: str) -> bool:
        """Check if account is locked"""
        lock_key = f"account_locked:{email}"
        return bool(self.redis_client.get(lock_key))
    
    def lock_account(self, email: str):
        """Lock account temporarily"""
        lock_key = f"account_locked:{email}"
        self.redis_client.setex(lock_key, self.lockout_duration, "1")
```

### 7. **Data Encryption**

#### Issue
- Sensitive data not encrypted at rest
- No encryption for database backups

#### Implementation Plan

**Phase 1: Database Encryption (Day 1-2)**
```python
from cryptography.fernet import Fernet
import json

class DataEncryption:
    def __init__(self):
        self.key = os.environ.get('ENCRYPTION_KEY')
        if not self.key:
            self.key = Fernet.generate_key()
            os.environ['ENCRYPTION_KEY'] = self.key.decode()
        self.cipher = Fernet(self.key)
    
    def encrypt_sensitive_data(self, data: dict) -> dict:
        """Encrypt sensitive fields in data"""
        sensitive_fields = ['phone', 'address', 'ssn', 'salary']
        encrypted_data = data.copy()
        
        for field in sensitive_fields:
            if field in encrypted_data and encrypted_data[field]:
                encrypted_data[field] = self.cipher.encrypt(
                    str(encrypted_data[field]).encode()
                ).decode()
        
        return encrypted_data
    
    def decrypt_sensitive_data(self, data: dict) -> dict:
        """Decrypt sensitive fields in data"""
        sensitive_fields = ['phone', 'address', 'ssn', 'salary']
        decrypted_data = data.copy()
        
        for field in sensitive_fields:
            if field in decrypted_data and decrypted_data[field]:
                try:
                    decrypted_data[field] = self.cipher.decrypt(
                        decrypted_data[field].encode()
                    ).decode()
                except:
                    # Handle corrupted data
                    decrypted_data[field] = None
        
        return decrypted_data
```

### 8. **Security Monitoring**

#### Issue
- No security event logging
- No intrusion detection

#### Implementation Plan

**Phase 1: Security Logging (Day 1-2)**
```python
import logging
from datetime import datetime

class SecurityLogger:
    def __init__(self):
        self.logger = logging.getLogger('security')
        self.logger.setLevel(logging.INFO)
        
        # File handler for security events
        fh = logging.FileHandler('security.log')
        fh.setLevel(logging.INFO)
        
        # Console handler for critical events
        ch = logging.StreamHandler()
        ch.setLevel(logging.WARNING)
        
        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        fh.setFormatter(formatter)
        ch.setFormatter(formatter)
        
        self.logger.addHandler(fh)
        self.logger.addHandler(ch)
    
    def log_failed_login(self, email: str, ip_address: str, user_agent: str):
        """Log failed login attempt"""
        self.logger.warning(
            f"Failed login attempt - Email: {email}, IP: {ip_address}, "
            f"User-Agent: {user_agent}"
        )
    
    def log_suspicious_activity(self, activity_type: str, details: dict):
        """Log suspicious activity"""
        self.logger.error(
            f"Suspicious activity detected - Type: {activity_type}, "
            f"Details: {details}"
        )
    
    def log_security_event(self, event_type: str, severity: str, details: dict):
        """Log general security events"""
        if severity == 'CRITICAL':
            self.logger.critical(f"CRITICAL: {event_type} - {details}")
        elif severity == 'HIGH':
            self.logger.error(f"HIGH: {event_type} - {details}")
        else:
            self.logger.warning(f"MEDIUM: {event_type} - {details}")
```

## Implementation Timeline

### Week 1: Critical Security Fixes
- **Day 1-2**: Remove exposed keys, implement secure token storage
- **Day 3-4**: Input validation and parameterized queries
- **Day 5**: Rate limiting and security headers

### Week 2: Authentication & Encryption
- **Day 1-2**: Password security and account lockout
- **Day 3-4**: Data encryption implementation
- **Day 5**: Security monitoring setup

### Week 3: Testing & Validation
- **Day 1-2**: Security testing
- **Day 3-4**: Penetration testing
- **Day 5**: Security audit and documentation

## Security Checklist

- [ ] Remove all hardcoded API keys
- [ ] Implement secure token storage (httpOnly cookies)
- [ ] Add input validation and sanitization
- [ ] Implement parameterized queries
- [ ] Add rate limiting to all endpoints
- [ ] Configure security headers and CORS
- [ ] Implement strong password requirements
- [ ] Add account lockout mechanism
- [ ] Encrypt sensitive data at rest
- [ ] Set up security monitoring and logging
- [ ] Conduct security testing
- [ ] Create security documentation

## Risk Assessment

| Security Issue | Risk Level | Impact | Mitigation |
|----------------|------------|--------|------------|
| Exposed API Keys | Critical | High | Immediate removal and rotation |
| XSS via localStorage | High | Medium | httpOnly cookies |
| SQL Injection | High | High | Parameterized queries |
| No Rate Limiting | Medium | Medium | Implement rate limiting |
| Weak Passwords | Medium | Medium | Strong password policy |
| No Encryption | Medium | High | Data encryption at rest |

## Success Metrics

- Zero exposed credentials in codebase
- 100% of API endpoints protected by rate limiting
- All user inputs validated and sanitized
- Security events logged and monitored
- Regular security audits scheduled
- Security documentation maintained 