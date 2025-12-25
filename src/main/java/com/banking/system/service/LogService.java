package com.banking.system.service;

import com.banking.system.entity.Log;
import com.banking.system.entity.User;
import com.banking.system.repository.LogRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

@Service
@Transactional
public class LogService {
    
    @Autowired
    private LogRepository logRepository;
    
    public Log createLog(String action, User user) {
        Log log = new Log(action, user);
        return logRepository.save(log);
    }
    
    public List<Log> getAllLogs() {
        return logRepository.findAllByOrderByTimestampDesc();
    }
    
    public List<Log> getLogsByUserId(Long userId) {
        return logRepository.findByUserIdOrderByTimestampDesc(userId);
    }
}
