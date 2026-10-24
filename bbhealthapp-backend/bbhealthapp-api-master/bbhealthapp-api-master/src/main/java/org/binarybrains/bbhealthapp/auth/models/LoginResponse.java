public class LoginResponse {
    private String token;
    private Object user;

    public LoginResponse(String token, Object user) {
        this.token = token;
        this.user = user;
    }

    public String getToken() { return token; }
    public Object getUser() { return user; }
}