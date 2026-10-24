// ===============================
// FRONTEND ENV CONFIG (FIXED)
// ===============================

// Read API base URL from environment variable or default to /api
const apiBaseUrl = process.env.REACT_APP_API_BASE_URL || '/api';

// When accessed through the ALB Ingress on EKS, we use relative paths 
// so the browser automatically sends requests to the ALB's domain.
const isK8s = !window.location.hostname.includes("localhost");

export const environment = isK8s ? {
  // MASTER SERVICE (Routed via ALB Ingress)
  MASTER_HOST_URL: `${apiBaseUrl}/master`,

  // AUTH / REGISTER SERVICE (Routed via ALB Ingress)
  REGISTER_BASE_URL: `${apiBaseUrl}/register`,
  LOGIN_URL: `${apiBaseUrl}/master/auth/login`,
  REGISTER_URL: `${apiBaseUrl}/register/auth/register`,
  DOCTOR_REGISTER_URL: `${apiBaseUrl}/register/auth/doctor/register`,
  TESTER_REGISTER_URL: `${apiBaseUrl}/register/auth/tester/register`,

  // DOCUMENT SERVICE (Routed via ALB Ingress)
  DOCUMENT_BASE_URL: `${apiBaseUrl}/document`,
  DOCUMENT_UPLOAD_URL: `${apiBaseUrl}/document/documents/upload`,
  DOCUMENT_DOWNLOAD_URL: `${apiBaseUrl}/document/documents/download`,
} : {
  // LOCAL DOCKER-COMPOSE FALLBACK
  MASTER_HOST_URL: `http://localhost:8081`,
  REGISTER_BASE_URL: `http://localhost:8082`,
  LOGIN_URL: `http://localhost:8081/auth/login`,
  REGISTER_URL: `http://localhost:8082/auth/register`,
  DOCTOR_REGISTER_URL: `http://localhost:8082/auth/doctor/register`,
  TESTER_REGISTER_URL: `http://localhost:8082/auth/tester/register`,
  DOCUMENT_BASE_URL: `http://localhost:8083`,
  DOCUMENT_UPLOAD_URL: `http://localhost:8083/documents/upload`,
  DOCUMENT_DOWNLOAD_URL: `http://localhost:8083/documents/download`,
};