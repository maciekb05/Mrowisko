-- panel.adb
--
-- materiały dydaktyczne
-- 2016
-- (c) Jacek Piwowarczyk
--

with Ada.Text_IO;
use Ada.Text_IO;
with Ada.Float_Text_IO;
use Ada.Float_Text_IO;

with Ada.Calendar;
use Ada.Calendar;
with Ada.Numerics.Float_Random;

with Ada.Strings;
use Ada.Strings;
with Ada.Strings.Fixed;
use Ada.Strings.Fixed;

with Ada.Exceptions;
use Ada.Exceptions;

procedure Panel is
  
  Koniec : Boolean := False with Atomic;
  
  type Atrybuty is (Czysty, Jasny, Podkreslony, Negatyw, Migajacy, Szary);

  protected Ekran  is
    procedure Pisz_XY(X,Y: Positive; S: String; Atryb : Atrybuty := Szary);
    procedure Pisz_Float_XY(X, Y: Positive; 
                            Num: Float; 
                            Pre: Natural := 3; 
                            Aft: Natural := 2; 
                            Exp: Natural := 0; 
                            Atryb : Atrybuty := Szary);
    procedure Czysc;
    procedure Tlo;
  end Ekran;
  
  protected body Ekran is
    -- implementacja dla Linuxa i macOSX
    function Atryb_Fun(Atryb : Atrybuty) return String is 
      (case Atryb is 
       when Jasny => "1m", when Podkreslony => "4m", when Negatyw => "7m",
       when Migajacy => "5m", when Szary => "2m", when Czysty => "0m"); 
       
    function Esc_XY(X,Y : Positive) return String is 
      ( (ASCII.ESC & "[" & Trim(Y'Img,Both) & ";" & Trim(X'Img,Both) & "H") );   
       
    procedure Pisz_XY(X,Y: Positive; S: String; Atryb : Atrybuty := Szary) is
      Przed : String := ASCII.ESC & "[" & Atryb_Fun(Atryb);              
    begin
      Put( Przed);
      Put( Esc_XY(X,Y) & S);
      Put( ASCII.ESC & "[0m");
    end Pisz_XY;  
    
    procedure Pisz_Float_XY(X, Y: Positive; 
                            Num: Float; 
                            Pre: Natural := 3; 
                            Aft: Natural := 2; 
                            Exp: Natural := 0; 
                            Atryb : Atrybuty := Szary) is
                              
      Przed_Str : String := ASCII.ESC & "[" & Atryb_Fun(Atryb);              
    begin
      Put( Przed_Str);
      Put( Esc_XY(X, Y) );
      Put( Num, Pre, Aft, Exp);
      Put( ASCII.ESC & "[0m");
    end Pisz_Float_XY; 
    
    procedure Czysc is
    begin
      Put(ASCII.ESC & "[2J");
    end Czysc;   
    
    procedure Tlo is
    begin
      Ekran.Czysc;
      Ekran.Pisz_XY(1,1,"+=========== Mrowisko ===========+");
      Ekran.Pisz_XY(3,5,"Ilość mrówek =");
      Ekran.Pisz_XY(3,6,"Ilość jajek =");
      Ekran.Pisz_XY(3,7,"Ilość larw =");
      Ekran.Pisz_XY(3,8,"Ilość poczwarek =");
    end Tlo; 
        
  end Ekran;
  
  task Przebieg;

  task body Przebieg is
    use Ada.Numerics.Float_Random;
    
    Nastepny     : Ada.Calendar.Time;
    Okres        : constant Duration := 0.99; -- sekundy
    Przesuniecie : constant Duration := 0.5;
    
    IloscMrowek : Integer := 0 with Atomic;
    IloscMrowekJajko : Integer := 0 with Atomic;
    IloscMrowekLarwa : Integer := 0 with Atomic;
    IloscMrowekPoczwarka : Integer := 0 with Atomic;
    IloscMrowekImago : Integer := 0 with Atomic;
    IloscMrowekStara : Integer := 0 with Atomic;

    type StanMrowki is (Jajko, Larwa, Poczwarka, Imago, Stara);

    task type Mrowka is
      entry Start;	
    end Mrowka;

    task body Mrowka is
      Wiek : Integer := 0;
      Stan : StanMrowki := Jajko;
      NastepnyM     : Ada.Calendar.Time;
      OkresM        : constant Duration := 3.0; -- sekundy
      PrzesuniecieM : constant Duration := 0.5;
    begin
      accept Start;
      IloscMrowek := IloscMrowek + 1;
      IloscMrowekJajko := IloscMrowekJajko + 1;
      NastepnyM := Clock + PrzesuniecieM;
      loop
        delay until NastepnyM;
        Wiek := Wiek + 1;

        case Wiek is
         when 2 =>
          IloscMrowekJajko := IloscMrowekJajko - 1;
          IloscMrowekLarwa := IloscMrowekLarwa + 1;
          Stan := Larwa;  
         when 4 => 
          IloscMrowekLarwa := IloscMrowekLarwa - 1;
          IloscMrowekPoczwarka := IloscMrowekPoczwarka + 1;
          Stan := Poczwarka;  
         when others => null; 
        end case;

        NastepnyM := NastepnyM + OkresM;
      end loop;
    end Mrowka;

    MaksymalnaIloscMrowek : Integer := 10;

    subtype Zakres is Integer range 1..MaksymalnaIloscMrowek; 
    Mrowki : array(Zakres) of Mrowka;

    Licznik : Integer := 1;

  begin
    Nastepny := Clock + Przesuniecie;
    loop
      delay until Nastepny;
      if Licznik <= MaksymalnaIloscMrowek
      then
        Mrowki(Licznik).Start;
        Licznik := Licznik + 1;
      end if;

      Ekran.Pisz_XY(21 ,5, 20*' ', Atryb=>Czysty);
      Ekran.Pisz_XY(21, 5, IloscMrowek'Img, Atryb=>Negatyw);
      Ekran.Pisz_XY(21 ,6, 20*' ', Atryb=>Czysty);
      Ekran.Pisz_XY(21, 6, IloscMrowekJajko'Img, Atryb=>Negatyw);
      Ekran.Pisz_XY(21 ,7, 20*' ', Atryb=>Czysty);
      Ekran.Pisz_XY(21, 7, IloscMrowekLarwa'Img, Atryb=>Negatyw);
      Ekran.Pisz_XY(21 ,8, 20*' ', Atryb=>Czysty);
      Ekran.Pisz_XY(21, 8, IloscMrowekPoczwarka'Img, Atryb=>Negatyw);
      exit when Koniec;
      Nastepny := Nastepny + Okres;
    end loop; 
    Ekran.Pisz_XY(1,11,"");
    exception
      when E:others =>
        Put_Line("Error: Zadanie Przebieg");
        Put_Line(Exception_Name (E) & ": " & Exception_Message (E)); 
  end Przebieg;

  Zn : Character;
  
begin
  -- inicjowanie
  Ekran.Tlo; 
  loop
    Get_Immediate(Zn);
    exit when Zn in 'q'|'Q';
  end loop; 
  Koniec := True;
end Panel;    