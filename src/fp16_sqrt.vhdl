--------------------------------------------------------------------------------
--                                FPSqrt_5_10
-- This operator is part of the Infinite Virtual Library FloPoCoLib
-- All rights reserved 
-- Authors: 
--------------------------------------------------------------------------------
-- Pipeline depth: 12 cycles

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library std;
use std.textio.all;
library work;

entity FPSqrt_5_10 is
   port ( clk, rst : in std_logic;
          X : in  std_logic_vector(5+10+2 downto 0);
          R : out  std_logic_vector(5+10+2 downto 0)   );
end entity;

architecture arch of FPSqrt_5_10 is
signal fracX :  std_logic_vector(9 downto 0);
signal eRn0 :  std_logic_vector(4 downto 0);
signal xsX, xsX_d1, xsX_d2, xsX_d3, xsX_d4, xsX_d5, xsX_d6, xsX_d7, xsX_d8, xsX_d9, xsX_d10, xsX_d11, xsX_d12 :  std_logic_vector(2 downto 0);
signal eRn1, eRn1_d1, eRn1_d2, eRn1_d3, eRn1_d4, eRn1_d5, eRn1_d6, eRn1_d7, eRn1_d8, eRn1_d9, eRn1_d10, eRn1_d11, eRn1_d12 :  std_logic_vector(4 downto 0);
signal w13 :  std_logic_vector(13 downto 0);
signal d12 :  std_logic;
signal x12 :  std_logic_vector(14 downto 0);
signal ds12 :  std_logic_vector(3 downto 0);
signal xh12 :  std_logic_vector(3 downto 0);
signal wh12 :  std_logic_vector(3 downto 0);
signal w12 :  std_logic_vector(13 downto 0);
signal s12 :  std_logic_vector(0 downto 0);
signal d11 :  std_logic;
signal x11 :  std_logic_vector(14 downto 0);
signal ds11 :  std_logic_vector(4 downto 0);
signal xh11 :  std_logic_vector(4 downto 0);
signal wh11 :  std_logic_vector(4 downto 0);
signal w11, w11_d1 :  std_logic_vector(13 downto 0);
signal s11, s11_d1 :  std_logic_vector(1 downto 0);
signal d10 :  std_logic;
signal x10 :  std_logic_vector(14 downto 0);
signal ds10 :  std_logic_vector(5 downto 0);
signal xh10 :  std_logic_vector(5 downto 0);
signal wh10 :  std_logic_vector(5 downto 0);
signal w10, w10_d1 :  std_logic_vector(13 downto 0);
signal s10, s10_d1 :  std_logic_vector(2 downto 0);
signal d9 :  std_logic;
signal x9 :  std_logic_vector(14 downto 0);
signal ds9 :  std_logic_vector(6 downto 0);
signal xh9 :  std_logic_vector(6 downto 0);
signal wh9 :  std_logic_vector(6 downto 0);
signal w9, w9_d1 :  std_logic_vector(13 downto 0);
signal s9, s9_d1 :  std_logic_vector(3 downto 0);
signal d8 :  std_logic;
signal x8 :  std_logic_vector(14 downto 0);
signal ds8 :  std_logic_vector(7 downto 0);
signal xh8 :  std_logic_vector(7 downto 0);
signal wh8 :  std_logic_vector(7 downto 0);
signal w8, w8_d1 :  std_logic_vector(13 downto 0);
signal s8, s8_d1 :  std_logic_vector(4 downto 0);
signal d7 :  std_logic;
signal x7 :  std_logic_vector(14 downto 0);
signal ds7 :  std_logic_vector(8 downto 0);
signal xh7 :  std_logic_vector(8 downto 0);
signal wh7 :  std_logic_vector(8 downto 0);
signal w7, w7_d1 :  std_logic_vector(13 downto 0);
signal s7, s7_d1 :  std_logic_vector(5 downto 0);
signal d6 :  std_logic;
signal x6 :  std_logic_vector(14 downto 0);
signal ds6 :  std_logic_vector(9 downto 0);
signal xh6 :  std_logic_vector(9 downto 0);
signal wh6 :  std_logic_vector(9 downto 0);
signal w6, w6_d1 :  std_logic_vector(13 downto 0);
signal s6, s6_d1 :  std_logic_vector(6 downto 0);
signal d5 :  std_logic;
signal x5 :  std_logic_vector(14 downto 0);
signal ds5 :  std_logic_vector(10 downto 0);
signal xh5 :  std_logic_vector(10 downto 0);
signal wh5 :  std_logic_vector(10 downto 0);
signal w5, w5_d1 :  std_logic_vector(13 downto 0);
signal s5, s5_d1 :  std_logic_vector(7 downto 0);
signal d4 :  std_logic;
signal x4 :  std_logic_vector(14 downto 0);
signal ds4 :  std_logic_vector(11 downto 0);
signal xh4 :  std_logic_vector(11 downto 0);
signal wh4 :  std_logic_vector(11 downto 0);
signal w4, w4_d1 :  std_logic_vector(13 downto 0);
signal s4, s4_d1 :  std_logic_vector(8 downto 0);
signal d3 :  std_logic;
signal x3 :  std_logic_vector(14 downto 0);
signal ds3 :  std_logic_vector(12 downto 0);
signal xh3 :  std_logic_vector(12 downto 0);
signal wh3 :  std_logic_vector(12 downto 0);
signal w3, w3_d1 :  std_logic_vector(13 downto 0);
signal s3, s3_d1 :  std_logic_vector(9 downto 0);
signal d2 :  std_logic;
signal x2 :  std_logic_vector(14 downto 0);
signal ds2 :  std_logic_vector(13 downto 0);
signal xh2 :  std_logic_vector(13 downto 0);
signal wh2 :  std_logic_vector(13 downto 0);
signal w2, w2_d1 :  std_logic_vector(13 downto 0);
signal s2, s2_d1 :  std_logic_vector(10 downto 0);
signal d1 :  std_logic;
signal x1 :  std_logic_vector(14 downto 0);
signal ds1 :  std_logic_vector(14 downto 0);
signal xh1 :  std_logic_vector(14 downto 0);
signal wh1 :  std_logic_vector(14 downto 0);
signal w1, w1_d1 :  std_logic_vector(13 downto 0);
signal s1, s1_d1 :  std_logic_vector(11 downto 0);
signal d0 :  std_logic;
signal fR :  std_logic_vector(13 downto 0);
signal fRn1, fRn1_d1 :  std_logic_vector(11 downto 0);
signal round, round_d1 :  std_logic;
signal fRn2 :  std_logic_vector(9 downto 0);
signal Rn2 :  std_logic_vector(14 downto 0);
signal xsR :  std_logic_vector(2 downto 0);
begin
   process(clk)
      begin
         if clk'event and clk = '1' then
            xsX_d1 <=  xsX;
            xsX_d2 <=  xsX_d1;
            xsX_d3 <=  xsX_d2;
            xsX_d4 <=  xsX_d3;
            xsX_d5 <=  xsX_d4;
            xsX_d6 <=  xsX_d5;
            xsX_d7 <=  xsX_d6;
            xsX_d8 <=  xsX_d7;
            xsX_d9 <=  xsX_d8;
            xsX_d10 <=  xsX_d9;
            xsX_d11 <=  xsX_d10;
            xsX_d12 <=  xsX_d11;
            eRn1_d1 <=  eRn1;
            eRn1_d2 <=  eRn1_d1;
            eRn1_d3 <=  eRn1_d2;
            eRn1_d4 <=  eRn1_d3;
            eRn1_d5 <=  eRn1_d4;
            eRn1_d6 <=  eRn1_d5;
            eRn1_d7 <=  eRn1_d6;
            eRn1_d8 <=  eRn1_d7;
            eRn1_d9 <=  eRn1_d8;
            eRn1_d10 <=  eRn1_d9;
            eRn1_d11 <=  eRn1_d10;
            eRn1_d12 <=  eRn1_d11;
            w11_d1 <=  w11;
            s11_d1 <=  s11;
            w10_d1 <=  w10;
            s10_d1 <=  s10;
            w9_d1 <=  w9;
            s9_d1 <=  s9;
            w8_d1 <=  w8;
            s8_d1 <=  s8;
            w7_d1 <=  w7;
            s7_d1 <=  s7;
            w6_d1 <=  w6;
            s6_d1 <=  s6;
            w5_d1 <=  w5;
            s5_d1 <=  s5;
            w4_d1 <=  w4;
            s4_d1 <=  s4;
            w3_d1 <=  w3;
            s3_d1 <=  s3;
            w2_d1 <=  w2;
            s2_d1 <=  s2;
            w1_d1 <=  w1;
            s1_d1 <=  s1;
            fRn1_d1 <=  fRn1;
            round_d1 <=  round;
         end if;
      end process;
   fracX <= X(9 downto 0); -- fraction
   eRn0 <= "0" & X(14 downto 11); -- exponent
   xsX <= X(17 downto 15); -- exception and sign
   eRn1 <= eRn0 + ("00" & (2 downto 0 => '1')) + X(10);
   w13 <= "111" & fracX & "0" when X(10) = '0' else
          "1101" & fracX;
   -- Step 12
   d12 <= w13(13);
   x12 <= w13 & "0";
   ds12 <=  "0" &  (not d12) & d12 & "1";
   xh12 <= x12(14 downto 11);
   with d12 select
      wh12 <= xh12 - ds12 when '0',
            xh12 + ds12 when others;
   w12 <= wh12(2 downto 0) & x12(10 downto 0);
   s12 <= "" & (not d12) ;
   -- Step 11
   d11 <= w12(13);
   x11 <= w12 & "0";
   ds11 <=  "0" & s12 &  (not d11) & d11 & "1";
   xh11 <= x11(14 downto 10);
   with d11 select
      wh11 <= xh11 - ds11 when '0',
            xh11 + ds11 when others;
   w11 <= wh11(3 downto 0) & x11(9 downto 0);
   s11 <= s12 & not d11;
   ----------------Synchro barrier, entering cycle 1----------------
   -- Step 10
   d10 <= w11_d1(13);
   x10 <= w11_d1 & "0";
   ds10 <=  "0" & s11_d1 &  (not d10) & d10 & "1";
   xh10 <= x10(14 downto 9);
   with d10 select
      wh10 <= xh10 - ds10 when '0',
            xh10 + ds10 when others;
   w10 <= wh10(4 downto 0) & x10(8 downto 0);
   s10 <= s11_d1 & not d10;
   ----------------Synchro barrier, entering cycle 2----------------
   -- Step 9
   d9 <= w10_d1(13);
   x9 <= w10_d1 & "0";
   ds9 <=  "0" & s10_d1 &  (not d9) & d9 & "1";
   xh9 <= x9(14 downto 8);
   with d9 select
      wh9 <= xh9 - ds9 when '0',
            xh9 + ds9 when others;
   w9 <= wh9(5 downto 0) & x9(7 downto 0);
   s9 <= s10_d1 & not d9;
   ----------------Synchro barrier, entering cycle 3----------------
   -- Step 8
   d8 <= w9_d1(13);
   x8 <= w9_d1 & "0";
   ds8 <=  "0" & s9_d1 &  (not d8) & d8 & "1";
   xh8 <= x8(14 downto 7);
   with d8 select
      wh8 <= xh8 - ds8 when '0',
            xh8 + ds8 when others;
   w8 <= wh8(6 downto 0) & x8(6 downto 0);
   s8 <= s9_d1 & not d8;
   ----------------Synchro barrier, entering cycle 4----------------
   -- Step 7
   d7 <= w8_d1(13);
   x7 <= w8_d1 & "0";
   ds7 <=  "0" & s8_d1 &  (not d7) & d7 & "1";
   xh7 <= x7(14 downto 6);
   with d7 select
      wh7 <= xh7 - ds7 when '0',
            xh7 + ds7 when others;
   w7 <= wh7(7 downto 0) & x7(5 downto 0);
   s7 <= s8_d1 & not d7;
   ----------------Synchro barrier, entering cycle 5----------------
   -- Step 6
   d6 <= w7_d1(13);
   x6 <= w7_d1 & "0";
   ds6 <=  "0" & s7_d1 &  (not d6) & d6 & "1";
   xh6 <= x6(14 downto 5);
   with d6 select
      wh6 <= xh6 - ds6 when '0',
            xh6 + ds6 when others;
   w6 <= wh6(8 downto 0) & x6(4 downto 0);
   s6 <= s7_d1 & not d6;
   ----------------Synchro barrier, entering cycle 6----------------
   -- Step 5
   d5 <= w6_d1(13);
   x5 <= w6_d1 & "0";
   ds5 <=  "0" & s6_d1 &  (not d5) & d5 & "1";
   xh5 <= x5(14 downto 4);
   with d5 select
      wh5 <= xh5 - ds5 when '0',
            xh5 + ds5 when others;
   w5 <= wh5(9 downto 0) & x5(3 downto 0);
   s5 <= s6_d1 & not d5;
   ----------------Synchro barrier, entering cycle 7----------------
   -- Step 4
   d4 <= w5_d1(13);
   x4 <= w5_d1 & "0";
   ds4 <=  "0" & s5_d1 &  (not d4) & d4 & "1";
   xh4 <= x4(14 downto 3);
   with d4 select
      wh4 <= xh4 - ds4 when '0',
            xh4 + ds4 when others;
   w4 <= wh4(10 downto 0) & x4(2 downto 0);
   s4 <= s5_d1 & not d4;
   ----------------Synchro barrier, entering cycle 8----------------
   -- Step 3
   d3 <= w4_d1(13);
   x3 <= w4_d1 & "0";
   ds3 <=  "0" & s4_d1 &  (not d3) & d3 & "1";
   xh3 <= x3(14 downto 2);
   with d3 select
      wh3 <= xh3 - ds3 when '0',
            xh3 + ds3 when others;
   w3 <= wh3(11 downto 0) & x3(1 downto 0);
   s3 <= s4_d1 & not d3;
   ----------------Synchro barrier, entering cycle 9----------------
   -- Step 2
   d2 <= w3_d1(13);
   x2 <= w3_d1 & "0";
   ds2 <=  "0" & s3_d1 &  (not d2) & d2 & "1";
   xh2 <= x2(14 downto 1);
   with d2 select
      wh2 <= xh2 - ds2 when '0',
            xh2 + ds2 when others;
   w2 <= wh2(12 downto 0) & x2(0 downto 0);
   s2 <= s3_d1 & not d2;
   ----------------Synchro barrier, entering cycle 10----------------
   -- Step 1
   d1 <= w2_d1(13);
   x1 <= w2_d1 & "0";
   ds1 <=  "0" & s2_d1 &  (not d1) & d1 & "1";
   xh1 <= x1(14 downto 0);
   with d1 select
      wh1 <= xh1 - ds1 when '0',
            xh1 + ds1 when others;
   w1 <= wh1(13 downto 0);
   s1 <= s2_d1 & not d1;
   ----------------Synchro barrier, entering cycle 11----------------
   d0 <= w1_d1(13) ;
   fR <= s1_d1 & not d0 & '1';
   -- normalisation of the result, removing leading 1
   with fR(13) select
      fRn1 <= fR(12 downto 2) & (fR(1) or fR(0)) when '1',
              fR(11 downto 0)                    when others;
   round <= fRn1(1) and (fRn1(2) or fRn1(0)) ; -- round  and (lsb or sticky) : that's RN, tie to even
   ----------------Synchro barrier, entering cycle 12----------------
   fRn2 <= fRn1_d1(11 downto 2) + ((9 downto 1 => '0') & round_d1); -- rounding sqrt never changes exponents 
   Rn2 <= eRn1_d12 & fRn2;
   -- sign and exception processing
   with xsX_d12 select
      xsR <= "010"  when "010",  -- normal case
             "100"  when "100",  -- +infty
             "000"  when "000",  -- +0
             "001"  when "001",  -- the infamous sqrt(-0)=-0
             "110"  when others; -- return NaN
   R <= xsR & Rn2; 
end architecture;

