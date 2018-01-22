// This test is mainly for simulation.
// It tests the correct functionality of the individual instructions.
// Instructions tested:
// 4C JMP a
// A9 LDA #
// 10 BPL r
// 30 BMI r
// 50 BVC r
// 70 BVS r
// 90 BCC r
// B0 BCS r
// D0 BNE r
// F0 BEQ r
// 18 CLC
// 38 SEC
// C9 CMP #
// AA TAX
// A8 TAY
// 8A TXA
// 98 TYA
// 85 STA d
// A5 LDA d
// 8D STA a
// AD LDA a

// To come:
// 49 EOR #
// 69 ADC #
// E9 SBC #
// 65 ADC d

// To come:
// A2 LDX #
// A0 LDY #
// CA DEX
// 88 DEY
// E8 INX
// C8 INY
// A6 LDX d
// A4 LDY d
// 86 STX d
// 84 STY d
// 9A TXS
// BA TSX


// Entry point after CPU reset
void __fastcall__ reset(void)
{
   // We assume that JMP works as expected.

   // First we test conditional branching forward
   // We also test that LDA # correctly sets the Z and S flags.
   __asm__("LDA #$00");
   __asm__("BNE %g", error1);    // Should not jump
   __asm__("BMI %g", error1);    // Should not jump
   __asm__("BEQ %g", noError1);  // Should jump
error1:
   __asm__("JMP %g", error1);
noError1:
   __asm__("BPL %g", noError1a); // Should jump
   __asm__("JMP %g", error1);

noError1a:
   __asm__("LDA #$FF");
   __asm__("BEQ %g", error2);    // Should not jump
   __asm__("BPL %g", error2);    // Should not jump
   __asm__("BNE %g", noError2);  // Should jump
error2:
   __asm__("JMP %g", error2);
noError2:
   __asm__("BMI %g", noError2a); // Should jump
   __asm__("JMP %g", error2);
noError2a:

   __asm__("CLC");
   __asm__("BCS %g", error3);    // Should not jump
   __asm__("BCC %g", noError3);  // Should jump
error3:
   __asm__("JMP %g", error3);
noError3:
   __asm__("SEC");
   __asm__("BCC %g", error4);    // Should not jump
   __asm__("BCS %g", noError4);  // Should jump
error4:
   __asm__("JMP %g", error4);

   // Next we test conditional branching backward
noError4c:
   __asm__("LDA #$FF");
   __asm__("BNE %g", noError5);  // Should jump
   __asm__("JMP %g", error4d);
noError4b:
   __asm__("LDA #$00");
   __asm__("BEQ %g", noError4c); // Should jump
   __asm__("JMP %g", error4d);
noError4a:
   __asm__("SEC");
   __asm__("LDA #$00");          // Verify carry is not altered
   __asm__("BCS %g", noError4b); // Should jump
   __asm__("JMP %g", error4d);
noError4:
   __asm__("CLC");
   __asm__("LDA #$00");          // Verify carry is not altered
   __asm__("BCC %g", noError4a); // Should jump
   __asm__("JMP %g", error4d);
error4d:
   __asm__("JMP %g", error4d);

noError5:
   // Now we test compare
   __asm__("SEC");               // Preset. Should be cleared in compare.
   __asm__("LDA #$55");
   __asm__("CMP #$AA");
   __asm__("BCS %g", error5a);   // Should not jump
   __asm__("BCC %g", noError5a); // Should jump
error5a:
   __asm__("JMP %g", error5a);
noError5a:
   __asm__("BEQ %g", error5a);   // Should not jump
   __asm__("BPL %g", error5a);   // Should not jump

   __asm__("CLC");               // Preclear. Should be set in compare.
   __asm__("CMP #$55");          // Verify value in Accumulator is unchanged.
   __asm__("BCC %g", error5c);   // Should not jump
   __asm__("BCS %g", noError5c); // Should jump
error5c:
   __asm__("JMP %g", error5c);
noError5c:
   __asm__("BNE %g", error5c);   // Should not jump
   __asm__("BMI %g", error5c);   // Should not jump

   __asm__("CLC");               // Preclear. Should be set in compare.
   __asm__("CMP #$33");
   __asm__("BCC %g", error5b);   // Should not jump
   __asm__("BCS %g", noError5b); // Should jump
error5b:
   __asm__("JMP %g", error5b);
noError5b:
   __asm__("BEQ %g", error5b);   // Should not jump
   __asm__("BMI %g", error5b);   // Should not jump

   // Now we test register transfers
   __asm__("LDA #$11");
   __asm__("TAX");
   __asm__("CMP #$11");          // Make sure A is not changed
   __asm__("BNE %g", error6);    // Should not jump

   __asm__("LDA #$22");
   __asm__("TAY");
   __asm__("CMP #$22");          // Make sure A is not changed
   __asm__("BNE %g", error6);    // Should not jump

   __asm__("LDA #$66");          // Put bogus value in register
   __asm__("TXA");
   __asm__("CMP #$11");
   __asm__("BNE %g", error6);    // Should not jump

   __asm__("TYA");
   __asm__("CMP #$22");
   __asm__("BEQ %g", noError6);    // Should jump
error6:
   __asm__("JMP %g", error6);
noError6:

   __asm__("TXA");               // Test X is not corrupted.
   __asm__("CMP #$11");
   __asm__("BNE %g", error6);    // Should not jump

   // Test register transfer sets flags correctly.
   __asm__("LDA #$88");          // Should set S=1 and Z=0.
   __asm__("BEQ %g", error6);    // Should not jump
   __asm__("BPL %g", error6);    // Should not jump
   __asm__("CMP #$88");          // Should set S=0 and Z=1.
   __asm__("BNE %g", error6);    // Should not jump
   __asm__("BMI %g", error6);    // Should not jump
   __asm__("TAX");               // Should set S=1 and Z=0.
   __asm__("BEQ %g", error6);    // Should not jump
   __asm__("BPL %g", error6);    // Should not jump

   __asm__("LDA #$99");          // Should set S=1 and Z=0.
   __asm__("BEQ %g", error6);    // Should not jump
   __asm__("BPL %g", error6);    // Should not jump
   __asm__("CMP #$99");          // Should set S=0 and Z=1.
   __asm__("BNE %g", error6);    // Should not jump
   __asm__("BMI %g", error6);    // Should not jump
   __asm__("TAY");               // Should set S=1 and Z=0.
   __asm__("BEQ %g", error6);    // Should not jump
   __asm__("BPL %g", error6);    // Should not jump

   __asm__("LDA #$00");          // Should set S=0 and Z=1.
   __asm__("TAX");               // Should set S=0 and Z=1.
   __asm__("TAY");               // Should set S=0 and Z=1.

   __asm__("CLC");               // Set C=0
   __asm__("LDA #$99");          // Should set S=1 and Z=0.
   __asm__("BEQ %g", error6);    // Should not jump
   __asm__("BPL %g", error6);    // Should not jump
   __asm__("TXA");               // Should set S=0 and Z=1.
   __asm__("BNE %g", error6);    // Should not jump
   __asm__("BMI %g", error6);    // Should not jump
   __asm__("BCS %g", error6);    // Should not jump

   __asm__("SEC");               // Set C=1
   __asm__("LDA #$AA");          // Should set S=1 and Z=0.
   __asm__("BEQ %g", error6);    // Should not jump
   __asm__("BPL %g", error6);    // Should not jump
   __asm__("TYA");               // Should set S=0 and Z=1.
   __asm__("BNE %g", error6);    // Should not jump
   __asm__("BMI %g", error6);    // Should not jump
   __asm__("BCC %g", error6);    // Should not jump


   // Now we test zero page memory
   __asm__("LDA #$11");
   __asm__("CMP #$11");          // Set S=0 and Z=1
   __asm__("BNE %g", error7);    // Should not jump
   __asm__("CLC");               // Set C=0
   __asm__("STA $00");           // Should leave Z and C unchanged.
   __asm__("BNE %g", error7);    // Should not jump
   __asm__("BCS %g", error7);    // Should not jump
   __asm__("CMP #$11");          // Make sure A is not changed
   __asm__("BEQ %g", noError7);  // Should jump
error7:
   __asm__("JMP %g", error7);
noError7:
   __asm__("SEC");               // Set C=1
   __asm__("LDA #$00");
   __asm__("STA $01");
   __asm__("BCC %g", error7);    // Should not jump
   __asm__("LDA #$AA");
   __asm__("STA $02");
   __asm__("LDA #$BB");
   __asm__("STA $03");
   __asm__("CMP #$BB");          // Make sure A is not changed
   __asm__("BNE %g", error7);    // Should not jump

   __asm__("LDA $00");           // Should read back #$11
   __asm__("BEQ %g", error7a);   // Should not jump
   __asm__("BMI %g", error7a);   // Should not jump
   __asm__("CMP #$11");
   __asm__("BNE %g", error7a);   // Should not jump

   __asm__("LDA $01");
   __asm__("BNE %g", error7a);   // Should not jump
   __asm__("BMI %g", error7a);   // Should not jump
   __asm__("TAX");
   __asm__("BNE %g", error7a);   // Should not jump
   __asm__("BMI %g", error7a);   // Should not jump

   __asm__("LDA $02");
   __asm__("BEQ %g", error7a);   // Should not jump
   __asm__("BPL %g", error7a);   // Should not jump
   __asm__("TAY");
   __asm__("BEQ %g", error7a);   // Should not jump
   __asm__("BPL %g", error7a);   // Should not jump

   __asm__("LDA $03");
   __asm__("CMP #$BB");
   __asm__("BNE %g", error7a);   // Should not jump
   __asm__("TXA");
   __asm__("CMP #$00");
   __asm__("BNE %g", error7a);   // Should not jump
   __asm__("TYA");
   __asm__("CMP #$AA");
   __asm__("BEQ %g", noError7a); // Should jump
error7a:
   __asm__("JMP %g", error7a);
noError7a:

   // Now we test absolute addressing
   __asm__("LDA #$11");
   __asm__("CMP #$11");          // Set S=0 and Z=1
   __asm__("BNE %g", error8);    // Should not jump
   __asm__("CLC");               // Set C=0
   __asm__("STA $0100");         // Should leave Z and C unchanged.
   __asm__("BNE %g", error8);    // Should not jump
   __asm__("BCS %g", error8);    // Should not jump
   __asm__("CMP #$11");          // Make sure A is not changed
   __asm__("BEQ %g", noError8);  // Should jump
error8:
   __asm__("JMP %g", error8);
noError8:
   __asm__("LDA #$00");
   __asm__("SEC");               // Set C=1
   __asm__("STA $0101");
   __asm__("BCC %g", error8);    // Should not jump
   __asm__("LDA #$AA");
   __asm__("STA $0102");
   __asm__("LDA #$BB");
   __asm__("STA $0103");
   __asm__("CMP #$BB");          // Make sure A is not changed
   __asm__("BNE %g", error8);    // Should not jump

   __asm__("LDA $0100");           // Should read back #$11
   __asm__("BEQ %g", error8a);   // Should not jump
   __asm__("BMI %g", error8a);   // Should not jump
   __asm__("CMP #$11");
   __asm__("BNE %g", error8a);   // Should not jump

   __asm__("LDA $0101");
   __asm__("BNE %g", error8a);   // Should not jump
   __asm__("BMI %g", error8a);   // Should not jump
   __asm__("TAX");
   __asm__("BNE %g", error8a);   // Should not jump
   __asm__("BMI %g", error8a);   // Should not jump

   __asm__("LDA $0102");         // AA
   __asm__("BEQ %g", error8a);   // Should not jump
   __asm__("BPL %g", error8a);   // Should not jump
   __asm__("TAY");
   __asm__("BEQ %g", error8a);   // Should not jump
   __asm__("BPL %g", error8a);   // Should not jump

   __asm__("LDA $0103");         // BB
   __asm__("CMP #$BB");
   __asm__("BNE %g", error8a);   // Should not jump
   __asm__("TXA");
   __asm__("CMP #$00");
   __asm__("BNE %g", error8a);   // Should not jump
   __asm__("TYA");
   __asm__("CMP #$AA");
   __asm__("BEQ %g", noError8a); // Should jump
error8a:
   __asm__("JMP %g", error8a);
noError8a:

   // Loop forever doing nothing
here:
   __asm__("LDA #$CC");          // Make it easy to recognize a successfull test.
   goto here;  // Just do an endless loop. Everything is run from the IRQ.
} // end of reset


// The interrupt service routine.
void __fastcall__ irq(void)
{
   __asm__("RTI");
} // end of irq


// Non-maskable interrupt
void __fastcall__ nmi(void)
{
   // Not used.
   __asm__("RTI");
} // end of nmi
