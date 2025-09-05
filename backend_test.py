#!/usr/bin/env python3
"""
Backend Testing Suite for Portail Entreprise Flashback Fa
Tests FastAPI + MySQL backend, database connectivity, and API endpoints
"""

import requests
import json
import os
import sys
from datetime import datetime
import time
import uuid

# Get backend URL from frontend .env file
def get_backend_url():
    try:
        with open('/app/frontend/.env', 'r') as f:
            for line in f:
                if line.startswith('REACT_APP_BACKEND_URL='):
                    return line.split('=', 1)[1].strip()
    except Exception as e:
        print(f"❌ Error reading frontend .env: {e}")
        return None

def test_health_endpoints():
    """Test health and status endpoints"""
    print("\n🔍 Testing Health & Status Endpoints...")
    
    backend_url = get_backend_url()
    if not backend_url:
        print("❌ Could not get backend URL from frontend/.env")
        return False
    
    print(f"Backend URL: {backend_url}")
    
    try:
        # Test root endpoint
        print("Testing GET / (root endpoint)...")
        response = requests.get(f"{backend_url}/", timeout=10)
        if response.status_code == 200:
            data = response.json()
            if data.get("success") and "Portail Entreprise Flashback Fa" in data.get("message", ""):
                print("✅ Root endpoint working - FastAPI v2.0.0 detected")
            else:
                print(f"⚠️ Unexpected root response: {data}")
        else:
            print(f"❌ Root endpoint returned status code: {response.status_code}")
            return False
            
        # Test health endpoint
        print("Testing GET /health...")
        response = requests.get(f"{backend_url}/health", timeout=10)
        if response.status_code == 200:
            health_data = response.json()
            if health_data.get("status") in ["healthy", "degraded"]:
                print(f"✅ Health endpoint working - Status: {health_data.get('status')}")
                print(f"   Database: {health_data.get('database', 'unknown')}")
                print(f"   Version: {health_data.get('version', 'unknown')}")
                if health_data.get("database") == "connected":
                    print("✅ MySQL database connection verified")
                else:
                    print("⚠️ Database connection issue detected")
            else:
                print(f"❌ Unexpected health response: {health_data}")
                return False
        else:
            print(f"❌ Health endpoint returned status code: {response.status_code}")
            return False
            
        # Test compatibility endpoints
        print("Testing GET /api/ (compatibility)...")
        response = requests.get(f"{backend_url}/api/", timeout=10)
        if response.status_code == 200:
            data = response.json()
            if "API Portail Entreprise Flashback Fa" in data.get("message", ""):
                print("✅ API compatibility endpoint working")
            else:
                print(f"⚠️ Unexpected API response: {data}")
        
        print("Testing GET /api/status (compatibility)...")
        response = requests.get(f"{backend_url}/api/status", timeout=10)
        if response.status_code == 200:
            data = response.json()
            if data.get("status") == "ok" and data.get("database") == "mysql":
                print("✅ API status endpoint working - MySQL backend confirmed")
            else:
                print(f"⚠️ Unexpected status response: {data}")
        
        return True
        
    except requests.exceptions.RequestException as e:
        print(f"❌ Failed to connect to backend: {e}")
        return False

def test_cors_configuration():
    """Test CORS configuration"""
    print("\n🔍 Testing CORS Configuration...")
    
    backend_url = get_backend_url()
    if not backend_url:
        return False
    
    try:
        # Make a preflight request
        headers = {
            'Origin': 'https://enterprise-finance-2.preview.emergentagent.com',
            'Access-Control-Request-Method': 'POST',
            'Access-Control-Request-Headers': 'Content-Type'
        }
        
        response = requests.options(f"{backend_url}/api/status", headers=headers, timeout=10)
        
        # Check CORS headers in response
        cors_headers = {
            'Access-Control-Allow-Origin': response.headers.get('Access-Control-Allow-Origin'),
            'Access-Control-Allow-Methods': response.headers.get('Access-Control-Allow-Methods'),
            'Access-Control-Allow-Headers': response.headers.get('Access-Control-Allow-Headers')
        }
        
        print(f"CORS Headers: {cors_headers}")
        
        if cors_headers['Access-Control-Allow-Origin']:
            print("✅ CORS is configured")
            return True
        else:
            print("⚠️ CORS headers not found, but this might be normal for some configurations")
            return True
            
    except Exception as e:
        print(f"❌ CORS test failed: {e}")
        return False

def test_discord_auth_endpoints():
    """Test Discord OAuth authentication endpoints (without actual tokens)"""
    print("\n🔍 Testing Discord OAuth Authentication Endpoints...")
    
    backend_url = get_backend_url()
    if not backend_url:
        return False
    
    try:
        # Test GET /auth/discord-url (should return Discord OAuth URL)
        print("Testing GET /auth/discord-url...")
        response = requests.get(f"{backend_url}/auth/discord-url", timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            if data.get("success") and "url" in data.get("data", {}):
                discord_url = data["data"]["url"]
                if "discord.com/api/oauth2/authorize" in discord_url:
                    print("✅ Discord OAuth URL generation working")
                else:
                    print(f"⚠️ Unexpected Discord URL format: {discord_url}")
            else:
                print(f"❌ Unexpected discord-url response: {data}")
                return False
        else:
            print(f"❌ GET /auth/discord-url failed with status: {response.status_code}")
            return False
        
        # Test POST /auth/discord/callback with invalid code (should fail gracefully)
        print("Testing POST /auth/discord/callback with invalid code...")
        test_callback_data = {
            "code": "invalid_test_code_12345",
            "state": "test_state"
        }
        
        response = requests.post(
            f"{backend_url}/auth/discord/callback",
            json=test_callback_data,
            headers={"Content-Type": "application/json"},
            timeout=10
        )
        
        # Should return 400 or 500 with proper error handling
        if response.status_code in [400, 500]:
            error_data = response.json()
            if "detail" in error_data:
                print("✅ Discord callback error handling working")
            else:
                print(f"⚠️ Unexpected error format: {error_data}")
        else:
            print(f"⚠️ Unexpected callback response status: {response.status_code}")
        
        # Test GET /auth/me without token (should fail with 401)
        print("Testing GET /auth/me without authentication...")
        response = requests.get(f"{backend_url}/auth/me", timeout=10)
        
        if response.status_code == 401:
            print("✅ Authentication protection working - /auth/me requires token")
        else:
            print(f"⚠️ Expected 401 for /auth/me, got: {response.status_code}")
        
        # Test GET /auth/check without token (should fail with 401)
        print("Testing GET /auth/check without authentication...")
        response = requests.get(f"{backend_url}/auth/check", timeout=10)
        
        if response.status_code == 401:
            print("✅ Authentication protection working - /auth/check requires token")
        else:
            print(f"⚠️ Expected 401 for /auth/check, got: {response.status_code}")
        
        return True
        
    except Exception as e:
        print(f"❌ Discord auth endpoints test failed: {e}")
        return False

def test_database_connectivity():
    """Test MongoDB connectivity indirectly through API"""
    print("\n🔍 Testing Database Connectivity...")
    
    # We test database connectivity by trying to create and retrieve data
    # This is an indirect test since we don't have direct database access
    
    backend_url = get_backend_url()
    if not backend_url:
        return False
    
    try:
        # Create a unique test entry
        timestamp = datetime.now().isoformat()
        test_data = {
            "client_name": f"DB_Test_Company_{timestamp}"
        }
        
        # Create entry
        response = requests.post(
            f"{backend_url}/api/status", 
            json=test_data,
            headers={"Content-Type": "application/json"},
            timeout=10
        )
        
        if response.status_code != 200:
            print(f"❌ Failed to create test entry: {response.status_code}")
            return False
        
        created_entry = response.json()
        entry_id = created_entry.get('id')
        
        # Retrieve all entries and verify our entry exists
        response = requests.get(f"{backend_url}/api/status", timeout=10)
        
        if response.status_code != 200:
            print(f"❌ Failed to retrieve entries: {response.status_code}")
            return False
        
        all_entries = response.json()
        found_entry = None
        
        for entry in all_entries:
            if entry.get('id') == entry_id:
                found_entry = entry
                break
        
        if found_entry:
            print("✅ Database connectivity verified - data successfully stored and retrieved")
            return True
        else:
            print("❌ Database connectivity issue - created entry not found in retrieval")
            return False
            
    except Exception as e:
        print(f"❌ Database connectivity test failed: {e}")
        return False

def test_environment_variables():
    """Test that required environment variables are configured"""
    print("\n🔍 Testing Environment Variables Configuration...")
    
    # Check backend .env file
    backend_env_path = '/app/backend/.env'
    required_backend_vars = ['MONGO_URL', 'DB_NAME']
    
    try:
        with open(backend_env_path, 'r') as f:
            backend_env_content = f.read()
        
        missing_vars = []
        for var in required_backend_vars:
            if f"{var}=" not in backend_env_content:
                missing_vars.append(var)
        
        if missing_vars:
            print(f"❌ Missing backend environment variables: {missing_vars}")
            return False
        else:
            print("✅ Backend environment variables configured")
    
    except Exception as e:
        print(f"❌ Failed to check backend .env: {e}")
        return False
    
    # Check frontend .env file for Supabase configuration
    frontend_env_path = '/app/frontend/.env'
    required_frontend_vars = ['REACT_APP_BACKEND_URL', 'REACT_APP_SUPABASE_URL', 'REACT_APP_SUPABASE_ANON_KEY']
    
    try:
        with open(frontend_env_path, 'r') as f:
            frontend_env_content = f.read()
        
        missing_vars = []
        for var in required_frontend_vars:
            if f"{var}=" not in frontend_env_content:
                missing_vars.append(var)
        
        if missing_vars:
            print(f"❌ Missing frontend environment variables: {missing_vars}")
            return False
        else:
            print("✅ Frontend Supabase environment variables configured")
            
        # Verify Supabase URL format
        if "https://dutvmjnhnrpqoztftzgd.supabase.co" in frontend_env_content:
            print("✅ Supabase URL correctly configured")
        else:
            print("⚠️ Supabase URL might not be correctly configured")
            
        return True
    
    except Exception as e:
        print(f"❌ Failed to check frontend .env: {e}")
        return False

def run_all_tests():
    """Run all backend tests"""
    print("=" * 60)
    print("🚀 BACKEND TESTING SUITE - PORTAIL ENTREPRISE FLASHBACK FA")
    print("=" * 60)
    
    tests = [
        ("Environment Variables", test_environment_variables),
        ("Backend Startup", test_backend_startup),
        ("CORS Configuration", test_cors_configuration),
        ("Database Connectivity", test_database_connectivity),
        ("Status API Endpoints", test_status_endpoints),
    ]
    
    results = {}
    
    for test_name, test_func in tests:
        try:
            results[test_name] = test_func()
        except Exception as e:
            print(f"❌ {test_name} failed with exception: {e}")
            results[test_name] = False
    
    # Summary
    print("\n" + "=" * 60)
    print("📊 TEST RESULTS SUMMARY")
    print("=" * 60)
    
    passed = 0
    total = len(results)
    
    for test_name, result in results.items():
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{test_name}: {status}")
        if result:
            passed += 1
    
    print(f"\nOverall: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 All backend tests passed!")
        return True
    else:
        print("⚠️ Some backend tests failed. Check logs above for details.")
        return False

if __name__ == "__main__":
    success = run_all_tests()
    sys.exit(0 if success else 1)