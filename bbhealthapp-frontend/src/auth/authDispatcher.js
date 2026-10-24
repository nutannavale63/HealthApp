import { environment } from "../environment";
import http from "../shared/services/http-service";
import { map, concatMap } from "rxjs/operators";
import { LOGOUT } from "./authStore";

// ===============================
// LOGIN
// ===============================

export const getToken = (loginRequest) => {
  return http.post(environment.LOGIN_URL, loginRequest).pipe(
    map((response) => response.token)
  );
};

export const doLogin = (loginRequest) => {
  clearAuthToken();

  return getToken(loginRequest).pipe(
    concatMap((token) => getMyDetailsWithToken(token))
  );
};

// ===============================
// USER DETAILS
// ===============================

const getMyDetailsWithToken = (token) => {
  const url = `${environment.MASTER_HOST_URL}/users/details`;

  setAuthToken(token);

  return http.get(url).pipe(
    map((userObject) => ({
      token,
      user: userObject,
    }))
  );
};

// ===============================
// REGISTER
// ===============================

export const doRegisterDoctor = (payload) => {
  return http.post(environment.DOCTOR_REGISTER_URL, payload);
};

export const doRegisterTester = (payload) => {
  return http.post(environment.TESTER_REGISTER_URL, payload);
};

export const doRegisterUser = (payload) => {
  return http.post(environment.REGISTER_URL, payload);
};

// ===============================
// DOCUMENT UPLOAD
// ===============================

export const doUploadDocument = (id, file) => {
  const url = environment.DOCUMENT_UPLOAD_URL + id;

  const formData = new FormData();
  formData.append("file", file);

  return http.uploadFileToServer(url, formData);
};

// ===============================
// AUTH HELPERS
// ===============================

export const setAuthToken = (token) => {
  http.setToken(token);
};

export const clearAuthToken = () => {
  http.setToken(null);
};

// ===============================
// LOGOUT
// ===============================

export const doLogout = (dispatch, history) => {
  dispatch({ type: LOGOUT });
  clearAuthToken();
  localStorage.clear();
  history.push("/");
};