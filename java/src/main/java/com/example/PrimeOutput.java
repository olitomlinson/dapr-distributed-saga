package com.example;

import java.util.List;

public class PrimeOutput {
    private List<Integer> primes;
    private int count;
    private int maxNumber;
    private long calculationTimeMs;

    public PrimeOutput() {
    }

    public PrimeOutput(List<Integer> primes, int count, int maxNumber, long calculationTimeMs) {
        this.primes = primes;
        this.count = count;
        this.maxNumber = maxNumber;
        this.calculationTimeMs = calculationTimeMs;
    }

    public List<Integer> getPrimes() {
        return primes;
    }

    public void setPrimes(List<Integer> primes) {
        this.primes = primes;
    }

    public int getCount() {
        return count;
    }

    public void setCount(int count) {
        this.count = count;
    }

    public int getMaxNumber() {
        return maxNumber;
    }

    public void setMaxNumber(int maxNumber) {
        this.maxNumber = maxNumber;
    }

    public long getCalculationTimeMs() {
        return calculationTimeMs;
    }

    public void setCalculationTimeMs(long calculationTimeMs) {
        this.calculationTimeMs = calculationTimeMs;
    }
}
