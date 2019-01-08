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
      Ekran.Pisz_XY(3,9,"Ilość trupów =");

      Ekran.Pisz_XY(3,11,"Ilość jedzenia =");

      Ekran.Pisz_XY(3,13,"Ilość pracujacych =");
      Ekran.Pisz_XY(3,14,"Ilość śpiących =");
      Ekran.Pisz_XY(3,15,"Ilość jedzących =");
      Ekran.Pisz_XY(3,16,"Ilość czekających =");
      Ekran.Pisz_XY(3,17,"Ilość rozmnazajacych =");


      Ekran.Pisz_XY(3,18,"Czas (sekundy):");
      Ekran.Pisz_XY(3,20,"Koniec - q, Kradziez 100 grzybow - k, Ciezsza praca - c");
      
    end Tlo; 
        
  end Ekran;
  
  task Przebieg is
    entry Kradziez;
    entry Pracujemy;
    entry NowaMrowka;
  end Przebieg;

  task body Przebieg is 

    Tick : Integer := 0;

    Nastepny     : Ada.Calendar.Time;
    Okres        : constant Duration := 1.0; -- sekundy
    Przesuniecie : constant Duration := 0.5;
    
    IloscMrowek : Integer := 0 with Atomic;
    IloscMrowekJajko : Integer := 0 with Atomic;
    IloscMrowekLarwa : Integer := 0 with Atomic;
    IloscMrowekPoczwarka : Integer := 0 with Atomic;
    IloscMrowekImago : Integer := 0 with Atomic;
    IloscMrowekStara : Integer := 0 with Atomic;
    IloscTrupow : Integer := 0 with Atomic;

    IloscSpiacychMrowek : Integer := 0 with Atomic;
    IloscJedzacychMrowek : Integer := 0 with Atomic;
    IloscCzekajacychMrowek : Integer := 0 with Atomic;
    IloscPracujacychMrowek : Integer := 0 with Atomic;
    IloscSkladajacychJaja : Integer := 0 with Atomic;

    IloscJedzenia : Integer := 0 with Atomic;
    CiezkoscPracy : Integer := 20 with Atomic;

    procedure UkradnijZarcie is
    begin
      IloscJedzenia := IloscJedzenia - 100;
    end UkradnijZarcie;

    procedure CiezkaPraca is
    begin
      CiezkoscPracy := CiezkoscPracy + 10;
    end CiezkaPraca;

    type StanMrowki is (Jajko, Larwa, Poczwarka, Imago, Stara);
    type CzynnosciMrowki is (Praca, Jedzenie, Spanie, Czekanie, SkadanieJaj);

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

    protected SemaforIlosciPracujacych is
        entry Czekaj;
        procedure Sygnalizuj;
    private
        Sem : Boolean := True;
    end SemaforIlosciPracujacych;

    protected body SemaforIlosciPracujacych is
        entry Czekaj when Sem is
        begin
            Sem := False;
        end Czekaj;

        procedure Sygnalizuj is
        begin
            Sem := True;
        end Sygnalizuj;
    end SemaforIlosciPracujacych;

    protected SemaforIlosciSpiacych is
        entry Czekaj;
        procedure Sygnalizuj;
    private
        Sem : Boolean := True;
    end SemaforIlosciSpiacych;

    protected body SemaforIlosciSpiacych is
        entry Czekaj when Sem is
        begin
            Sem := False;
        end Czekaj;

        procedure Sygnalizuj is
        begin
            Sem := True;
        end Sygnalizuj;
    end SemaforIlosciSpiacych;

    protected SemaforIlosciJedzacych is
        entry Czekaj;
        procedure Sygnalizuj;
    private
        Sem : Boolean := True;
    end SemaforIlosciJedzacych;

    protected body SemaforIlosciJedzacych is
        entry Czekaj when Sem is
        begin
            Sem := False;
        end Czekaj;

        procedure Sygnalizuj is
        begin
            Sem := True;
        end Sygnalizuj;
    end SemaforIlosciJedzacych;

    protected SemaforIlosciCzekajacych is
        entry Czekaj;
        procedure Sygnalizuj;
    private
        Sem : Boolean := True;
    end SemaforIlosciCzekajacych;

    protected body SemaforIlosciCzekajacych is
        entry Czekaj when Sem is
        begin
            Sem := False;
        end Czekaj;

        procedure Sygnalizuj is
        begin
            Sem := True;
        end Sygnalizuj;
    end SemaforIlosciCzekajacych;

    protected SemaforIlosciRozmnazajacych is
        entry Czekaj;
        procedure Sygnalizuj;
    private
        Sem : Boolean := True;
    end SemaforIlosciRozmnazajacych;

    protected body SemaforIlosciRozmnazajacych is
        entry Czekaj when Sem is
        begin
            Sem := False;
        end Czekaj;

        procedure Sygnalizuj is
        begin
            Sem := True;
        end Sygnalizuj;
    end SemaforIlosciRozmnazajacych;

    protected SemaforMrowek is
        entry Czekaj;
        procedure Sygnalizuj;
    private
        Sem : Boolean := True;
    end SemaforMrowek;

    protected body SemaforMrowek is
        entry Czekaj when Sem is
        begin
            Sem := False;
        end Czekaj;

        procedure Sygnalizuj is
        begin
            Sem := True;
        end Sygnalizuj;
    end SemaforMrowek;

    protected SemaforJajek is
        entry Czekaj;
        procedure Sygnalizuj;
    private
        Sem : Boolean := True;
    end SemaforJajek;

    protected body SemaforJajek is
        entry Czekaj when Sem is
        begin
            Sem := False;
        end Czekaj;

        procedure Sygnalizuj is
        begin
            Sem := True;
        end Sygnalizuj;
    end SemaforJajek;

    protected SemaforLarw is
        entry Czekaj;
        procedure Sygnalizuj;
    private
        Sem : Boolean := True;
    end SemaforLarw;

    protected body SemaforLarw is
        entry Czekaj when Sem is
        begin
            Sem := False;
        end Czekaj;

        procedure Sygnalizuj is
        begin
            Sem := True;
        end Sygnalizuj;
    end SemaforLarw;

    protected SemaforPoczwarek is
        entry Czekaj;
        procedure Sygnalizuj;
    private
        Sem : Boolean := True;
    end SemaforPoczwarek;

    protected body SemaforPoczwarek is
        entry Czekaj when Sem is
        begin
            Sem := False;
        end Czekaj;

        procedure Sygnalizuj is
        begin
            Sem := True;
        end Sygnalizuj;
    end SemaforPoczwarek;

    protected SemaforImago is
        entry Czekaj;
        procedure Sygnalizuj;
    private
        Sem : Boolean := True;
    end SemaforImago;

    protected body SemaforImago is
        entry Czekaj when Sem is
        begin
            Sem := False;
        end Czekaj;

        procedure Sygnalizuj is
        begin
            Sem := True;
        end Sygnalizuj;
    end SemaforImago;
    
    protected SemaforStarych is
        entry Czekaj;
        procedure Sygnalizuj;
    private
        Sem : Boolean := True;
    end SemaforStarych;

    protected body SemaforStarych is
        entry Czekaj when Sem is
        begin
            Sem := False;
        end Czekaj;

        procedure Sygnalizuj is
        begin
            Sem := True;
        end Sygnalizuj;
    end SemaforStarych;

    protected SemaforTrupow is
        entry Czekaj;
        procedure Sygnalizuj;
    private
        Sem : Boolean := True;
    end SemaforTrupow;

    protected body SemaforTrupow is
        entry Czekaj when Sem is
        begin
            Sem := False;
        end Czekaj;

        procedure Sygnalizuj is
        begin
            Sem := True;
        end Sygnalizuj;
    end SemaforTrupow;

    task type Mrowka is
      entry Start;	
    end Mrowka;

    task body Mrowka is
      use Ada.Numerics.Float_Random;

      Gen : Generator;

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
      PrzesuniecieM : constant Duration := 0.4;

      procedure PorzucPoprzedniaCzynnosc is begin
        case Czynnosc is
          when Praca =>
            SemaforIlosciPracujacych.Czekaj;
            IloscPracujacychMrowek := IloscPracujacychMrowek - 1;
            SemaforIlosciPracujacych.Sygnalizuj;
          when Jedzenie => 
            SemaforIlosciJedzacych.Czekaj;
            IloscJedzacychMrowek := IloscJedzacychMrowek - 1;
            SemaforIlosciJedzacych.Sygnalizuj;
          when Spanie => 
            SemaforIlosciSpiacych.Czekaj;
            IloscSpiacychMrowek := IloscSpiacychMrowek - 1;
            SemaforIlosciSpiacych.Sygnalizuj;
          when Czekanie => 
            SemaforIlosciCzekajacych.Czekaj;
            IloscCzekajacychMrowek := IloscCzekajacychMrowek - 1;
            SemaforIlosciCzekajacych.Sygnalizuj;
          when SkadanieJaj => 
            SemaforIlosciRozmnazajacych.Czekaj;
            IloscSkladajacychJaja := IloscSkladajacychJaja - 1;
            SemaforIlosciRozmnazajacych.Sygnalizuj;
        end case;
      end PorzucPoprzedniaCzynnosc;

    begin
      Reset(Gen);
      accept Start;
      SemaforMrowek.Czekaj;
      IloscMrowek := IloscMrowek + 1;
      SemaforMrowek.Sygnalizuj;
      SemaforJajek.Czekaj;
      IloscMrowekJajko := IloscMrowekJajko + 1;
      SemaforJajek.Sygnalizuj;
      SemaforIlosciCzekajacych.Czekaj;
      IloscCzekajacychMrowek := IloscCzekajacychMrowek + 1;
      SemaforIlosciCzekajacych.Sygnalizuj;
      NastepnyM := Clock + PrzesuniecieM;
      loop
        delay until NastepnyM;
        Wiek := Wiek + 1;

        case Wiek is
         when 2 =>
          SemaforJajek.Czekaj;
          IloscMrowekJajko := IloscMrowekJajko - 1;
          SemaforJajek.Sygnalizuj;
          SemaforLarw.Czekaj;
          IloscMrowekLarwa := IloscMrowekLarwa + 1;
          SemaforLarw.Sygnalizuj;
          Stan := Larwa;  
         when 4 => 
          SemaforLarw.Czekaj;
          IloscMrowekLarwa := IloscMrowekLarwa - 1;
          SemaforLarw.Sygnalizuj;
          SemaforPoczwarek.Czekaj;
          IloscMrowekPoczwarka := IloscMrowekPoczwarka + 1;
          SemaforPoczwarek.Sygnalizuj;
          Stan := Poczwarka;
         when 8 => 
          SemaforPoczwarek.Czekaj;
          IloscMrowekPoczwarka := IloscMrowekPoczwarka - 1;
          SemaforPoczwarek.Sygnalizuj;
          SemaforImago.Czekaj;
          IloscMrowekImago := IloscMrowekImago + 1;
          SemaforImago.Sygnalizuj;
          Stan := Imago;
         when 16 => 
          SemaforImago.Czekaj;
          IloscMrowekImago := IloscMrowekImago - 1;
          SemaforImago.Sygnalizuj;
          SemaforStarych.Czekaj;
          IloscMrowekStara := IloscMrowekStara + 1;
          SemaforStarych.Sygnalizuj;
          Stan := Stara;
         when 32 =>
          SemaforMrowek.Czekaj;
          IloscMrowek := IloscMrowek - 1;
          SemaforMrowek.Sygnalizuj;
          SemaforStarych.Czekaj;
          IloscMrowekStara := IloscMrowekStara - 1;
          SemaforStarych.Sygnalizuj;
          SemaforTrupow.Czekaj;
          IloscTrupow := IloscTrupow + 1;
          SemaforTrupow.Sygnalizuj;
          
          PorzucPoprzedniaCzynnosc;

          exit;
         when others => null; 
        end case;


        if Stan = Imago or else Stan = Stara
        then

          if PoziomNajedzenia <= 0 or else Energia <= 0
          then
            SemaforMrowek.Czekaj;
            IloscMrowek := IloscMrowek - 1;
            SemaforMrowek.Sygnalizuj;
            SemaforTrupow.Czekaj;
            IloscTrupow := IloscTrupow + 1;
            SemaforTrupow.Sygnalizuj;
            if Wiek >= 16
            then 
              SemaforStarych.Czekaj;
              IloscMrowekStara := IloscMrowekStara - 1;
              SemaforStarych.Sygnalizuj;
            else
              SemaforImago.Czekaj;
              IloscMrowekImago := IloscMrowekImago - 1;
              SemaforImago.Sygnalizuj;
            end if;
            PorzucPoprzedniaCzynnosc;
            exit;
          end if;

          if Energia < 21
          then
            SemaforSpania.Czekaj;
              if Float(IloscSpiacychMrowek) / Float(IloscMrowek) < 0.2
              then
                PorzucPoprzedniaCzynnosc;
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
              if IloscJedzenia > 5
              then
                PorzucPoprzedniaCzynnosc;
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
              PorzucPoprzedniaCzynnosc;
              Czynnosc := Czekanie;
              SemaforIlosciCzekajacych.Czekaj;
              IloscCzekajacychMrowek := IloscCzekajacychMrowek + 1;
              SemaforIlosciCzekajacych.Sygnalizuj;
              Energia := Energia - 3;
              PoziomNajedzenia := PoziomNajedzenia - 5;
            elsif Random(Gen) < 0.08 then
              PorzucPoprzedniaCzynnosc;
              Czynnosc := SkadanieJaj;
              SemaforIlosciRozmnazajacych.Czekaj;
              IloscSkladajacychJaja := IloscSkladajacychJaja + 1;
              SemaforIlosciRozmnazajacych.Sygnalizuj;
              Energia := Energia - 5;
              PoziomNajedzenia := PoziomNajedzenia - 10;
              Przebieg.NowaMrowka;
            else
              PorzucPoprzedniaCzynnosc;
              Czynnosc := Praca;
              SemaforIlosciPracujacych.Czekaj;
              IloscPracujacychMrowek := IloscPracujacychMrowek + 1;
              SemaforIlosciPracujacych.Sygnalizuj;
              Energia := Energia - CiezkoscPracy;
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

    MaksymalnaIloscMrowek : Integer := 100;

    subtype Zakres is Integer range 1..MaksymalnaIloscMrowek; 
    Mrowki : array(Zakres) of Mrowka;

    Licznik : Integer := 1 with Atomic;
  begin
    
    Nastepny := Clock + Przesuniecie;
    loop
      delay until Nastepny;

      select
        accept Kradziez do
          UkradnijZarcie;
        end Kradziez;
      or
        accept Pracujemy do
          CiezkaPraca;
        end Pracujemy;
      or
        accept NowaMrowka do
          if Licznik <= MaksymalnaIloscMrowek
          then
            Mrowki(Licznik).Start;
            Licznik := Licznik + 1;
          end if;
        end NowaMrowka;
      else
        null;
      end select;

      if Licznik <= 10
      then
        Mrowki(Licznik).Start;
        Licznik := Licznik + 1;
      end if;

      Tick := Tick + 1;

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
      Ekran.Pisz_XY(21, 9, IloscTrupow'Img, Atryb=>Negatyw);


      Ekran.Pisz_XY(21 ,11, 20*' ', Atryb=>Czysty);
      Ekran.Pisz_XY(21, 11, IloscJedzenia'Img, Atryb=>Negatyw);

      Ekran.Pisz_XY(28 ,13, 20*' ', Atryb=>Czysty);
      Ekran.Pisz_XY(28, 13, IloscPracujacychMrowek'Img, Atryb=>Negatyw);
      Ekran.Pisz_XY(28 ,14, 20*' ', Atryb=>Czysty);
      Ekran.Pisz_XY(28, 14, IloscSpiacychMrowek'Img, Atryb=>Negatyw);
      Ekran.Pisz_XY(28 ,15, 20*' ', Atryb=>Czysty);
      Ekran.Pisz_XY(28, 15, IloscJedzacychMrowek'Img, Atryb=>Negatyw);
      Ekran.Pisz_XY(28 ,16, 20*' ', Atryb=>Czysty);
      Ekran.Pisz_XY(28, 16, IloscCzekajacychMrowek'Img, Atryb=>Negatyw);
      Ekran.Pisz_XY(28 ,17, 20*' ', Atryb=>Czysty);
      Ekran.Pisz_XY(28, 17, IloscSkladajacychJaja'Img, Atryb=>Negatyw);


      Ekran.Pisz_XY(21 ,18, 20*' ', Atryb=>Czysty);
      Ekran.Pisz_XY(21, 18, Tick'Img, Atryb=>Negatyw);

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
    if Zn in 'K'|'k' 
    then 
      Przebieg.Kradziez;
    elsif Zn in 'C' | 'c'
    then 
      Przebieg.Pracujemy;
    end if;
  end loop; 
  Koniec := True;
end Panel;    