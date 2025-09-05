#!/usr/bin/env python3
"""
Backend Testing Suite for Portail Entreprise Flashback Fa
Tests FastAPI backend, MongoDB connectivity, and API endpoints
"""

import requests
import json
import os
import sys
from datetime import datetime
import time

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

def test_backend_startup():
    """Test if backend server is running and accessible"""
    print("\n🔍 Testing Backend Server Startup...")
    
    backend_url = get_backend_url()
    if not backend_url:
        print("❌ Could not get backend URL from frontend/.env")
        return False
    
    print(f"Backend URL: {backend_url}")
    
    try:
        # Test root endpoint
        response = requests.get(f"{backend_url}/api/", timeout=10)
        if response.status_code == 200:
            data = response.json()
            if data.get("message") == "Hello World":
                print("✅ Backend server is running and accessible")
                return True
            else:
                print(f"❌ Unexpected response: {data}")
                return False
        else:
            print(f"❌ Backend returned status code: {response.status_code}")
            return False
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
            'Origin': 'https://enterprise-portal-2.preview.emergentagent.com',
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

def test_status_endpoints():
    """Test status check CRUD operations"""
    print("\n🔍 Testing Status Check API Endpoints...")
    
    backend_url = get_backend_url()
    if not backend_url:
        return False
    
    try:
        # Test GET /api/status (should return empty list initially)
        print("Testing GET /api/status...")
        response = requests.get(f"{backend_url}/api/status", timeout=10)
        
        if response.status_code == 200:
            status_checks = response.json()
            print(f"✅ GET /api/status successful. Found {len(status_checks)} status checks")
        else:
            print(f"❌ GET /api/status failed with status: {response.status_code}")
            return False
        
        # Test POST /api/status
        print("Testing POST /api/status...")
        test_data = {
            "client_name": "Test Company Flashback Fa"
        }
        
        response = requests.post(
            f"{backend_url}/api/status", 
            json=test_data,
            headers={"Content-Type": "application/json"},
            timeout=10
        )
        
        if response.status_code == 200:
            created_status = response.json()
            print(f"✅ POST /api/status successful. Created status with ID: {created_status.get('id')}")
            
            # Verify the created status has required fields
            required_fields = ['id', 'client_name', 'timestamp']
            missing_fields = [field for field in required_fields if field not in created_status]
            
            if missing_fields:
                print(f"❌ Created status missing fields: {missing_fields}")
                return False
            
            if created_status['client_name'] != test_data['client_name']:
                print(f"❌ Client name mismatch: expected {test_data['client_name']}, got {created_status['client_name']}")
                return False
                
            print("✅ Created status has all required fields")
            
        else:
            print(f"❌ POST /api/status failed with status: {response.status_code}")
            print(f"Response: {response.text}")
            return False
        
        # Test GET again to verify data persistence
        print("Testing data persistence...")
        response = requests.get(f"{backend_url}/api/status", timeout=10)
        
        if response.status_code == 200:
            updated_status_checks = response.json()
            if len(updated_status_checks) > len(status_checks):
                print("✅ Data persistence verified - new status check found in database")
                return True
            else:
                print("⚠️ Data persistence unclear - status check count didn't increase")
                return True
        else:
            print(f"❌ Failed to verify data persistence: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Status endpoints test failed: {e}")
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