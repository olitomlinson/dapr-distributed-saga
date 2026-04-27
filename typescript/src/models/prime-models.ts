export interface PrimeInput {
  maxNumber: number;
}

export interface PrimeOutput {
  primes: number[];
  count: number;
  maxNumber: number;
  calculationTimeMs: number;
}
