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
      Ekran.Pisz_XY(3,3,"Ilość ogółem =");
      Ekran.Pisz_XY(3,4,"Ilość jajek =");
      Ekran.Pisz_XY(3,5,"Ilość larw =");
      Ekran.Pisz_XY(3,6,"Ilość poczwarek =");
      Ekran.Pisz_XY(3,7,"Ilość imago =");
      Ekran.Pisz_XY(3,8,"Ilość starych =");
      Ekran.Pisz_XY(3,9,"Ilość jedzenia =");

      Ekran.Pisz_XY(3,11,"Ilość pracujacych =");
      Ekran.Pisz_XY(3,12,"Ilość śpiących =");
      Ekran.Pisz_XY(3,13,"Ilość jedzących =");
      Ekran.Pisz_XY(3,14,"Ilość czekających =");
      
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

    IloscSpiacychMrowek : Integer := 0 with Atomic;
    IloscJedzacychMrowek : Integer := 0 with Atomic;
    IloscCzekajacychMrowek : Integer := 0 with Atomic;
    IloscPracujacychMrowek : Integer := 0 with Atomic;

    IloscJedzenia : Integer := 0 with Atomic;

    type StanMrowki is (Jajko, Larwa, Poczwarka, Imago, Stara);
    type CzynnosciMrowki is (Praca, Jedzenie, Spanie, Czekanie);

    protected SemaforJedzenia is
        entry Czekaj;
        procedure Sygnalizuj;
    private
        Sem : Boolean := True;
    end SemaforJedzenia;

    protected body SemaforJedzenia is
        entry Czekaj when Sem is
        begin
            Sem := False;
        end Czekaj;

        procedure Sygnalizuj is
        begin
            Sem := True;
        end Sygnalizuj;
    end SemaforJedzenia;

    protected SemaforSpania is
        entry Czekaj;
        procedure Sygnalizuj;
    private
        Sem : Boolean := True;
    end SemaforSpania;

    protected body SemaforSpania is
        entry Czekaj when Sem is
        begin
            Sem := False;
        end Czekaj;

        procedure Sygnalizuj is
        begin
            Sem := True;
        end Sygnalizuj;
    end SemaforSpania;


    task type Mrowka is
      entry Start;	
    end Mrowka;

    task body Mrowka is
      Energia : Integer := 100;
      PoziomNajedzenia : Integer := 100;
      Czynnosc : CzynnosciMrowki := Czekanie;

      ZmienilemStan : Boolean := false;
      CzekamNaSpanie : Boolean := false;
      CzekamNaJedzenie : Boolean := false;

      Wiek : Integer := 0;
      Stan : StanMrowki := Jajko;
      NastepnyM     : Ada.Calendar.Time;
      OkresM        : constant Duration := 3.0; -- sekundy
      PrzesuniecieM : constant Duration := 0.5;
    begin
      accept Start;
      IloscMrowek := IloscMrowek + 1;
      IloscMrowekJajko := IloscMrowekJajko + 1;
      IloscCzekajacychMrowek := IloscCzekajacychMrowek + 1;
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
         when 8 => 
          IloscMrowekPoczwarka := IloscMrowekPoczwarka - 1;
          IloscMrowekImago := IloscMrowekImago + 1;
          Stan := Imago;
         when 16 => 
          IloscMrowekImago := IloscMrowekImago - 1;
          IloscMrowekStara := IloscMrowekStara + 1;
          Stan := Stara;
         when 32 =>
          IloscMrowek := IloscMrowek - 1;
          IloscMrowekStara := IloscMrowekStara - 1;
          case Czynnosc is
            when Praca => IloscPracujacychMrowek := IloscPracujacychMrowek - 1;
            when Jedzenie => IloscJedzacychMrowek := IloscJedzacychMrowek - 1;
            when Spanie => IloscSpiacychMrowek := IloscSpiacychMrowek - 1;
            when Czekanie => IloscCzekajacychMrowek := IloscCzekajacychMrowek - 1;
          end case;
          exit;
         when others => null; 
        end case;

        

        if Stan = Imago or else Stan = Stara
        then

          case Czynnosc is
            when Praca => IloscPracujacychMrowek := IloscPracujacychMrowek - 1;
            when Jedzenie => IloscJedzacychMrowek := IloscJedzacychMrowek - 1;
            when Spanie => IloscSpiacychMrowek := IloscSpiacychMrowek - 1;
            when Czekanie => IloscCzekajacychMrowek := IloscCzekajacychMrowek - 1;
          end case;

          if PoziomNajedzenia <= 0 or else Energia <= 0
          then
            IloscMrowek := IloscMrowek - 1;
            if Wiek >= 16
            then 
              IloscMrowekStara := IloscMrowekStara - 1;
            else
              IloscMrowekImago := IloscMrowekImago - 1;
            end if;
            exit;
          end if;

          if Energia < 21
          then
            SemaforSpania.Czekaj;
              if Float(IloscSpiacychMrowek) / Float(IloscMrowek) < 0.2
              then
                Czynnosc := Spanie;
                IloscSpiacychMrowek := IloscSpiacychMrowek + 1;
                Energia := Energia + 80;
                PoziomNajedzenia := PoziomNajedzenia - 10;
                CzekamNaSpanie := false;
                ZmienilemStan := true;
              else
                CzekamNaSpanie := true;
                ZmienilemStan := false;
              end if;
            SemaforSpania.Sygnalizuj;
          end if;

          if PoziomNajedzenia < 21 and then ZmienilemStan = false
          then
            SemaforJedzenia.Czekaj;
              if IloscJedzenia > 0
              then
                Czynnosc := Jedzenie;
                IloscJedzacychMrowek := IloscJedzacychMrowek + 1;
                PoziomNajedzenia := PoziomNajedzenia + 50;
                Energia := Energia - 10;
                IloscJedzenia := IloscJedzenia - 5;
                CzekamNaJedzenie := false;
                ZmienilemStan := true;
              else
                CzekamNaJedzenie := true;
                ZmienilemStan := false;
              end if;
            SemaforJedzenia.Sygnalizuj;
          end if;
          
          if ZmienilemStan = false
          then
            if CzekamNaJedzenie = true or else CzekamNaSpanie = true 
            then
              Czynnosc := Czekanie;
              IloscCzekajacychMrowek := IloscCzekajacychMrowek + 1;
              Energia := Energia - 3;
              PoziomNajedzenia := PoziomNajedzenia - 5;
            else 
              Czynnosc := Praca;
              IloscPracujacychMrowek := IloscPracujacychMrowek + 1;
              Energia := Energia - 20;
              PoziomNajedzenia := PoziomNajedzenia - 30;
              IloscJedzenia := IloscJedzenia + 3;
            end if;
          end if;

        else
          Czynnosc := Czekanie;
        end if;

        CzekamNaJedzenie := false;
        CzekamNaSpanie := false;
        ZmienilemStan := false;

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

      Ekran.Pisz_XY(21 ,3, 20*' ', Atryb=>Czysty);
      Ekran.Pisz_XY(21, 3, IloscMrowek'Img, Atryb=>Negatyw);
      Ekran.Pisz_XY(21 ,4, 20*' ', Atryb=>Czysty);
      Ekran.Pisz_XY(21, 4, IloscMrowekJajko'Img, Atryb=>Negatyw);
      Ekran.Pisz_XY(21 ,5, 20*' ', Atryb=>Czysty);
      Ekran.Pisz_XY(21, 5, IloscMrowekLarwa'Img, Atryb=>Negatyw);
      Ekran.Pisz_XY(21 ,6, 20*' ', Atryb=>Czysty);
      Ekran.Pisz_XY(21, 6, IloscMrowekPoczwarka'Img, Atryb=>Negatyw);
      Ekran.Pisz_XY(21 ,7, 20*' ', Atryb=>Czysty);
      Ekran.Pisz_XY(21, 7, IloscMrowekImago'Img, Atryb=>Negatyw);
      Ekran.Pisz_XY(21 ,8, 20*' ', Atryb=>Czysty);
      Ekran.Pisz_XY(21, 8, IloscMrowekStara'Img, Atryb=>Negatyw);
      Ekran.Pisz_XY(21 ,9, 20*' ', Atryb=>Czysty);
      Ekran.Pisz_XY(21, 9, IloscJedzenia'Img, Atryb=>Negatyw);

      Ekran.Pisz_XY(28 ,11, 20*' ', Atryb=>Czysty);
      Ekran.Pisz_XY(28, 11, IloscPracujacychMrowek'Img, Atryb=>Negatyw);
      Ekran.Pisz_XY(28 ,12, 20*' ', Atryb=>Czysty);
      Ekran.Pisz_XY(28, 12, IloscSpiacychMrowek'Img, Atryb=>Negatyw);
      Ekran.Pisz_XY(28 ,13, 20*' ', Atryb=>Czysty);
      Ekran.Pisz_XY(28, 13, IloscJedzacychMrowek'Img, Atryb=>Negatyw);
      Ekran.Pisz_XY(28 ,14, 20*' ', Atryb=>Czysty);
      Ekran.Pisz_XY(28, 14, IloscCzekajacychMrowek'Img, Atryb=>Negatyw);

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