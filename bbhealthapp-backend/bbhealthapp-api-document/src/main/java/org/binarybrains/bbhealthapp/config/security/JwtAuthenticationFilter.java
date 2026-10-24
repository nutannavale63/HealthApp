package org.binarybrains.bbhealthapp.config.security;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

import javax.servlet.FilterChain;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

public class JwtAuthenticationFilter extends OncePerRequestFilter {

    static final String TOKEN_PREFIX = "Bearer ";
    static final String HEADER_STRING = "Authorization";

    @Autowired
    private TokenProvider tokenProvider;

    @Override
    protected void doFilterInternal(HttpServletRequest req,
                                    HttpServletResponse res,
                                    FilterChain chain)
            throws IOException, ServletException {

        String header = req.getHeader(HEADER_STRING);

        String username = null;
        String authToken = null;

        if (header != null && header.startsWith(TOKEN_PREFIX)) {
            authToken = header.replace(TOKEN_PREFIX, "");
            username = tokenProvider.getUsernameFromToken(authToken);
        }

        if (username != null &&
                SecurityContextHolder.getContext().getAuthentication() == null) {

            setSecurityContextAuthenticationIn(req, username, authToken);
        }

        chain.doFilter(req, res);
    }

    private void setSecurityContextAuthenticationIn(HttpServletRequest req,
                                                     String username,
                                                     String authToken) {

        // If you already had full JWT logic, keep it here
        // For now safe minimal version:

        SecurityContextHolder.getContext().setAuthentication(
                new org.springframework.security.authentication.UsernamePasswordAuthenticationToken(
                        username, null, java.util.Collections.emptyList()
                )
        );
    }
}