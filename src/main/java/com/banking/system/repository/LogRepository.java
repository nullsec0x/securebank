package com.banking.system.repository;

import com.banking.system.entity.Log;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface LogRepository extends JpaRepository<Log, Long> {
    List<Log> findAllByOrderByTimestampDesc();
    List<Log> findByUserIdOrderByTimestampDesc(Long userId);
}
