package com.banking.system.repository;

import com.banking.system.entity.Transaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface TransactionRepository extends JpaRepository<Transaction, Long> {
    List<Transaction> findByAccountIdOrderByTimestampDesc(Long accountId);
    List<Transaction> findByAccount_User_IdOrderByTimestampDesc(Long userId);
}
