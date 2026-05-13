package com.burgerbuilder;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@SpringBootApplication
public class BurgerBuilderApplication {

    public static void main(String[] args) {
        SpringApplication.run(BurgerBuilderApplication.class, args);
    }
    
    @Bean
    public WebMvcConfigurer corsConfigurer(
            @Value("${app.cors.allowed-origins:http://localhost:5173,http://localhost:3000}") String allowedOrigins) {
        final String[] origins = allowedOrigins.split("\\s*,\\s*");

        return new WebMvcConfigurer() {
            @Override
            public void addCorsMappings(CorsRegistry registry) {
                registry.addMapping("/**")
                        .allowedOrigins(origins)
                        .allowedMethods("*")
                        .allowedHeaders("*");
            }
        };
    }
}
