package com.banking.system.config;

import com.banking.system.entity.User;
import com.banking.system.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
public class DataLoader implements CommandLineRunner {
    
    @Autowired
    private UserService userService;
    
    @Autowired
    private PasswordEncoder passwordEncoder;
    
    @Override
    public void run(String... args) throws Exception {
        System.out.println("\n=== DATALOADER STARTING ===");
        
        // FIRST: Debug existing users
        userService.debugAllUsers();
        
        // DELETE existing demo users first (if they exist)
        try {
            User existingAdmin = userService.getUserByUsername("admin");
            System.out.println("Found existing admin, checking password...");
            System.out.println("Admin password: " + existingAdmin.getPassword());
            System.out.println("Is BCrypt? " + existingAdmin.getPassword().startsWith("$2a$"));
            
            // Test if password works
            boolean matches = passwordEncoder.matches("admin123", existingAdmin.getPassword());
            System.out.println("Password 'admin123' matches stored hash? " + matches);
        } catch (Exception e) {
            System.out.println("No existing admin user found: " + e.getMessage());
        }
        
        // Create or recreate admin user
        try {
            System.out.println("\n--- Creating/Updating Admin User ---");
            User admin = userService.createUser("admin", "admin123", User.Role.ADMIN);
            System.out.println("✓ Admin user created/updated: " + admin.getUsername());
        } catch (Exception e) {
            System.out.println("Note: " + e.getMessage());
        }
        
        // Create or recreate sample user
        try {
            System.out.println("\n--- Creating/Updating Sample User ---");
            User john = userService.createUser("john", "password123", User.Role.USER);
            System.out.println("✓ Sample user created/updated: " + john.getUsername());
        } catch (Exception e) {
            System.out.println("Note: " + e.getMessage());
        }
        
        // FINAL: Debug all users again
        System.out.println("\n=== FINAL USER CHECK ===");
        userService.debugAllUsers();
        
        System.out.println("\n=== DATALOADER FINISHED ===\n");
    }
}
