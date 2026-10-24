@Override
protected void configure(HttpSecurity http) throws Exception {

    http.cors().and().csrf().disable()
        .authorizeRequests()
        .antMatchers(
            "/auth/**",
            "/h2-console/**"
        ).permitAll()
        .anyRequest().authenticated()
        .and()
        .sessionManagement()
        .sessionCreationPolicy(SessionCreationPolicy.STATELESS);

    http.headers().frameOptions().disable();
}