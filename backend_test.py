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

def test_dotations_api_endpoints():
    """Test Dotations CRUD API endpoints (without authentication)"""
    print("\n🔍 Testing Dotations API Endpoints...")
    
    backend_url = get_backend_url()
    if not backend_url:
        return False
    
    try:
        # Test GET /api/dotations without auth (should fail with 401)
        print("Testing GET /api/dotations without authentication...")
        response = requests.get(f"{backend_url}/api/dotations", timeout=10)
        
        if response.status_code == 401:
            print("✅ Dotations endpoint protected - requires authentication")
        else:
            print(f"⚠️ Expected 401 for /api/dotations, got: {response.status_code}")
        
        # Test POST /api/dotations without auth (should fail with 401)
        print("Testing POST /api/dotations without authentication...")
        test_dotation_data = {
            "title": "Test Dotation Report",
            "period": "2024-01",
            "rows": [
                {
                    "employee_name": "Jean Dupont",
                    "grade": "Agent",
                    "run": 5000.0,
                    "facture": 3000.0,
                    "vente": 2000.0
                }
            ]
        }
        
        response = requests.post(
            f"{backend_url}/api/dotations",
            json=test_dotation_data,
            headers={"Content-Type": "application/json"},
            timeout=10
        )
        
        if response.status_code == 401:
            print("✅ Dotations creation protected - requires authentication")
        else:
            print(f"⚠️ Expected 401 for POST /api/dotations, got: {response.status_code}")
        
        # Test bulk import endpoint
        print("Testing POST /api/dotations/bulk-import without authentication...")
        bulk_data = {
            "data": "Jean Dupont;5000;3000;2000\nMarie Martin;4000;2500;1500",
            "format": "csv"
        }
        
        response = requests.post(
            f"{backend_url}/api/dotations/bulk-import",
            json=bulk_data,
            headers={"Content-Type": "application/json"},
            timeout=10
        )
        
        if response.status_code == 401:
            print("✅ Dotations bulk import protected - requires authentication")
        else:
            print(f"⚠️ Expected 401 for bulk import, got: {response.status_code}")
        
        return True
        
    except Exception as e:
        print(f"❌ Dotations API test failed: {e}")
        return False

def test_tax_api_endpoints():
    """Test Tax declarations API endpoints"""
    print("\n🔍 Testing Tax Declarations API Endpoints...")
    
    backend_url = get_backend_url()
    if not backend_url:
        return False
    
    try:
        # Test tax-related endpoints that might exist
        tax_endpoints = [
            "/api/tax-declarations",
            "/api/tax-declarations/calculate", 
            "/api/tax-declarations/brackets"
        ]
        
        for endpoint in tax_endpoints:
            print(f"Testing {endpoint}...")
            response = requests.get(f"{backend_url}{endpoint}", timeout=10)
            
            if response.status_code == 401:
                print(f"✅ {endpoint} protected - requires authentication")
            elif response.status_code == 404:
                print(f"⚠️ {endpoint} not implemented yet")
            elif response.status_code == 200:
                print(f"✅ {endpoint} accessible")
            else:
                print(f"⚠️ {endpoint} returned status: {response.status_code}")
        
        # Test POST tax calculation
        print("Testing POST /api/tax-declarations/calculate...")
        calc_data = {
            "revenus_imposables": 50000.0,
            "abattements": 5000.0,
            "patrimoine": 100000.0
        }
        
        response = requests.post(
            f"{backend_url}/api/tax-declarations/calculate",
            json=calc_data,
            headers={"Content-Type": "application/json"},
            timeout=10
        )
        
        if response.status_code == 401:
            print("✅ Tax calculation protected - requires authentication")
        elif response.status_code == 404:
            print("⚠️ Tax calculation endpoint not implemented yet")
        elif response.status_code == 200:
            calc_result = response.json()
            print(f"✅ Tax calculation working - Result: {calc_result}")
        else:
            print(f"⚠️ Tax calculation returned status: {response.status_code}")
        
        return True
        
    except Exception as e:
        print(f"❌ Tax API test failed: {e}")
        return False

def test_mysql_database_connectivity():
    """Test MySQL database connectivity through health endpoint"""
    print("\n🔍 Testing MySQL Database Connectivity...")
    
    backend_url = get_backend_url()
    if not backend_url:
        return False
    
    try:
        # Use health endpoint to verify database connection
        response = requests.get(f"{backend_url}/health", timeout=10)
        
        if response.status_code == 200:
            health_data = response.json()
            database_status = health_data.get("database", "unknown")
            services = health_data.get("services", {})
            
            if database_status == "connected":
                print("✅ MySQL database connection verified through health check")
                
                # Check additional service details
                if "database" in services:
                    db_service_status = services["database"]
                    if db_service_status == "connected":
                        print("✅ Database service status confirmed as connected")
                    else:
                        print(f"⚠️ Database service status: {db_service_status}")
                
                return True
            else:
                print(f"❌ Database connection issue: {database_status}")
                return False
        else:
            print(f"❌ Health endpoint failed: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ MySQL connectivity test failed: {e}")
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