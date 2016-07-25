--    Copyright 2016 Bartek thindil Jasicki
--    
--    This file is part of Steam Sky.
--
--    Steam Sky is free software: you can redistribute it and/or modify
--    it under the terms of the GNU General Public License as published by
--    the Free Software Foundation, either version 3 of the License, or
--    (at your option) any later version.
--
--    Steam Sky is distributed in the hope that it will be useful,
--    but WITHOUT ANY WARRANTY; without even the implied warranty of
--    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--    GNU General Public License for more details.
--
--    You should have received a copy of the GNU General Public License
--    along with Steam Sky.  If not, see <http://www.gnu.org/licenses/>.

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Directories; use Ada.Directories;
with Maps; use Maps;
with Ships; use Ships;
with Crew; use Crew;
with Bases; use Bases;
with Prototypes; use Prototypes;
with Messages; use Messages;

package body UserInterface is

    MemberIndex : Natural;

    procedure ShowMainMenu is
        Visibility : Cursor_Visibility := Invisible;
    begin
        Set_Echo_Mode(False);
        Set_Cursor_Visibility(Visibility);

        -- Game logo
        Move_Cursor(Line => Lines / 5, Column => (Columns - 15) / 2);
        Add(Str => "STEAM SKY");
        Move_Cursor(Line => (Lines / 5) + 1, Column => (Columns - 12) / 2);
        -- Game version
        Add(Str => "ver 0.2");
        Move_Cursor(Line => (Lines / 3) + 1, Column => (Columns - 12) / 2);
        -- Game menu
        Add(Str => "New game");
        Change_Attributes(Line => (Lines / 3) + 1, Column => (Columns - 12) / 2,
            Count => 1, Color => 1);
        if Exists("data/savegame.dat") then
            Move_Cursor(Line => (Lines / 3) + 2, Column => (Columns - 12) / 2);
            Add(Str => "Load game");
            Change_Attributes(Line => (Lines / 3) + 2, Column => (Columns - 12) / 2,
                Count => 1, Color => 1);
            Move_Cursor(Line => (Lines / 3) + 3, Column => (Columns - 12) / 2);
            Add(Str => "Quit game");
            Change_Attributes(Line => (Lines / 3) + 3, Column => (Columns - 12) / 2,
                Count => 1, Color => 1);
        else
            Move_Cursor(Line => (Lines / 3) + 2, Column => (Columns - 12) / 2);
            Add(Str => "Quit game");
            Change_Attributes(Line => (Lines / 3) + 2, Column => (Columns - 12) / 2,
                Count => 1, Color => 1);
        end if;
        -- Copyright
        Move_Cursor(Line => Lines - 1, Column => (Columns - 20) / 2);
        Add(Str => "2016 Bartek thindil Jasicki");
    end ShowMainMenu;

    procedure ShowGameMenu(CurrentState : GameStates) is
        Speed : Unbounded_String;
    begin
        case CurrentState is
            when Sky_Map_View =>
                Add(Str => "[Ship] [Crew] [Orders] [Messages] [Help] [Quit]");
                Change_Attributes(Line => 0, Column => 1, Count => 1, Color => 1);
                Change_Attributes(Line => 0, Column => 8, Count => 1, Color => 1);
                Change_Attributes(Line => 0, Column => 15, Count => 1, Color => 1);
                Change_Attributes(Line => 0, Column => 24, Count => 1, Color => 1);
                Change_Attributes(Line => 0, Column => 35, Count => 1, Color => 1);
                Change_Attributes(Line => 0, Column => 42, Count => 1, Color => 1);
            when Ship_Info =>
                Add(Str => "Ship Informations [Quit]");
                Change_Attributes(Line => 0, Column => 19, Count => 1, Color => 1);
            when Crew_Info =>
                Add(Str => "Crew Informations [Quit]");
                Change_Attributes(Line => 0, Column => 19, Count => 1, Color => 1);
            when Messages_View =>
                Add(Str => "Last Messages [Quit]");
                Change_Attributes(Line => 0, Column => 15, Count => 1, Color => 1);
            when Trade_View =>
                Add(Str => "Trade with base [Quit]");
                Change_Attributes(Line => 0, Column => 17, Count => 1, Color => 1);
            when Help_View =>
                Add(Str => "Help [Quit]");
                Change_Attributes(Line => 0, Column => 6, Count => 1, Color => 1);
            when others =>
                null;
        end case;
        if CurrentState /= Help_View then
            case PlayerShip.Speed is
                when DOCKED =>
                    Speed := To_Unbounded_String("Docked");
                when FULL_STOP =>
                    Speed := To_Unbounded_String("Stopped");
                when QUARTER_SPEED =>
                    Speed := To_Unbounded_String("Quarter Speed");
                when HALF_SPEED =>
                    Speed := To_Unbounded_String("Half Speed");
                when FULL_SPEED =>
                    Speed := To_Unbounded_String("Full Speed");
            end case;
            Move_Cursor(Line => 0, Column => (Columns / 2));
            Add(Str => FormatedTime & "     Speed: " & To_String(Speed));
        end if;
    end ShowGameMenu;

    procedure ShowSpeedControl is
        SpeedWindow : Window;
    begin
        SpeedWindow := Create(10, 20, (Lines / 3), (Columns / 3));
        Box(SpeedWindow);
        if PlayerShip.Speed = DOCKED then
            Move_Cursor(Win => SpeedWindow, Line => 3, Column => 5);
            Add(Win => SpeedWindow, Str => "Undock");
            Change_Attributes(Win => SpeedWindow, Line => 3, Column => 5, 
                Count => 1, Color => 1);
            Move_Cursor(Win => SpeedWindow, Line => 4, Column => 5);
            Add(Win => SpeedWindow, Str => "Trade");
            Change_Attributes(Win => SpeedWindow, Line => 4, Column => 5, 
                Count => 1, Color => 1);
        else
            if SkyMap(PlayerShip.SkyX, PlayerShip.SkyY).BaseIndex > 0 then
                Move_Cursor(Win => SpeedWindow, Line => 2, Column => 5);
                Add(Win => SpeedWindow, Str => "Dock");
                Change_Attributes(Win => SpeedWindow, Line => 2, Column => 5, 
                    Count => 1, Color => 1);
            end if;
            Move_Cursor(Win => SpeedWindow, Line => 3, Column => 5);
            Add(Win => SpeedWindow, Str => "Full stop");
            Change_Attributes(Win => SpeedWindow, Line => 3, Column => 5, 
                Count => 1, Color => 1);
            Move_Cursor(Win => SpeedWindow, Line => 4, Column => 5);
            Add(Win => SpeedWindow, Str => "Quarter speed");
            Change_Attributes(Win => SpeedWindow, Line => 4, Column => 7, 
                Count => 1, Color => 1);
            Move_Cursor(Win => SpeedWindow, Line => 5, Column => 5);
            Add(Win => SpeedWindow, Str => "Half speed");
            Change_Attributes(Win => SpeedWindow, Line => 5, Column => 5, 
                Count => 1, Color => 1);
            Move_Cursor(Win => SpeedWindow, Line => 6, Column => 5);
            Add(Win => SpeedWindow, Str => "Full speed");
            Change_Attributes(Win => SpeedWindow, Line => 6, Column => 7, 
                Count => 1, Color => 1);
        end if;
        Move_Cursor(Win => SpeedWindow, Line => 8, Column => 5);
        Add(Win => SpeedWindow, Str => "Quit");
        Change_Attributes(Win => SpeedWindow, Line => 8, Column => 5, Count => 1,
            Color => 1);
        Refresh(SpeedWindow);
    end ShowSpeedControl;

    procedure ShowShipInfo is
        Weight : Integer;
        CargoWeight : Positive;
    begin
        Weight := 0;
        Move_Cursor(Line => 2, Column => 2);
        Add(Str => "Speed: ");
        case PlayerShip.Speed is
            when DOCKED =>
                Add(Str => "Stopped (Docked to base)");
            when FULL_STOP =>
                Add(Str => "Stopped");
            when QUARTER_SPEED =>
                Add(Str => "Quarter speed");
            when HALF_SPEED =>
                Add(Str => "Half speed");
            when FULL_SPEED =>
                Add(Str => "Full speed");
        end case;
        Move_Cursor(Line => 4, Column => 2);
        Add(Str => "STATUS:");
        for I in PlayerShip.Modules.First_Index..PlayerShip.Modules.Last_Index loop
            Move_Cursor(Line => Line_Position(4 + I), Column => 2);
            Add(Str => To_String(PlayerShip.Modules.Element(I).Name) & ": ");
            if PlayerShip.Modules.Element(I).Durability < PlayerShip.Modules.Element(I).MaxDurability then
                Add(Str => "Damaged");
            else
                Add(Str => "OK");
            end if;
            Weight := Weight + PlayerShip.Modules.Element(I).Weight;
        end loop;
        Move_Cursor(Line => 4, Column => (Columns / 2));
        Add(Str => "CARGO:");
        for I in PlayerShip.Cargo.First_Index..PlayerShip.Cargo.Last_Index loop
            CargoWeight := PlayerShip.Cargo.Element(I).Amount * Objects_Prototypes(PlayerShip.Cargo.Element(I).ProtoIndex).Weight;
            Move_Cursor(Line => Line_Position(4 + I), Column => (Columns / 2));
            Add(Str => Positive'Image(PlayerShip.Cargo.Element(I).Amount) & "x" &
                To_String(Objects_Prototypes(PlayerShip.Cargo.Element(I).ProtoIndex).Name) & " (" &
                Positive'Image(CargoWeight) & "kg )");
            Weight := Weight + CargoWeight;
        end loop;
        Move_Cursor(Line => 3, Column => 2);
        Add(Str => "Weight: " & Integer'Image(Weight) & "kg");
    end ShowShipInfo;

    procedure ShowCrewInfo(Key : Key_Code) is
        Health, Tired, Hungry, Thirsty, SkillLevel, OrderName : Unbounded_String;
        Skills_Names : constant array (1..4) of Unbounded_String := (To_Unbounded_String("Piloting"), 
            To_Unbounded_String("Engineering"), To_Unbounded_String("Gunnery"), 
            To_Unbounded_String("Bartering"));
    begin
        if Key /= KEY_NONE then
            Erase;
            Refresh;
            ShowGameMenu(Crew_Info);
        end if;
        for I in PlayerShip.Crew.First_Index..PlayerShip.Crew.Last_Index loop
            Move_Cursor(Line => Line_Position(2 + I), Column => 2);
            Add(Str => Character'Val(96 + I) & " " & To_String(PlayerShip.Crew.Element(I).Name));
            Change_Attributes(Line => Line_Position(2 + I), Column => 2, Count => 1, Color => 1);
            if PlayerShip.Crew.Element(I).Health = 100 then
                Health := To_Unbounded_String("");
            elsif PlayerShip.Crew.Element(I).Health < 100 and PlayerShip.Crew.Element(I).Health > 50 then
                Health := To_Unbounded_String(" Wounded");
            elsif PlayerShip.Crew.Element(I).Health < 51 and PlayerShip.Crew.Element(I).Health > 0 then
                Health := To_Unbounded_String(" Heavily Wounded");
            else
                Health := To_Unbounded_String(" Dead");
            end if;
            if PlayerShip.Crew.Element(I).Tired = 0 then
                Tired := To_Unbounded_String("");
            elsif PlayerShip.Crew.Element(I).Tired > 0 and PlayerShip.Crew(I).Tired < 41 then
                Tired := To_Unbounded_String(" Tired");
            elsif PlayerShip.Crew.Element(I).Tired > 40 and PlayerShip.Crew(I).Tired < 100 then
                Tired := To_Unbounded_String(" Very tired");
            else
                Tired := To_Unbounded_String(" Unconscious");
            end if;
            if PlayerShip.Crew.Element(I).Hunger = 0 then
                Hungry := To_Unbounded_String("");
            elsif PlayerShip.Crew.Element(I).Hunger > 0 and PlayerShip.Crew(I).Hunger < 41 then
                Hungry := To_Unbounded_String(" Hungry");
            elsif PlayerShip.Crew.Element(I).Hunger > 40 and PlayerShip.Crew(I).Hunger < 100 then
                Hungry := To_Unbounded_String(" Very hungry");
            else
                Hungry := To_Unbounded_String(" Starving");
            end if;
            if PlayerShip.Crew.Element(I).Thirst = 0 then
                Thirsty := To_Unbounded_String("");
            elsif PlayerShip.Crew.Element(I).Thirst > 0 and PlayerShip.Crew(I).Thirst < 41 then
                Thirsty := To_Unbounded_String(" Thirsty");
            elsif PlayerShip.Crew.Element(I).Thirst > 40 and PlayerShip.Crew(I).Thirst < 100 then
                Thirsty := To_Unbounded_String(" Very thirsty");
            else
                Thirsty := To_Unbounded_String(" Dehydrated");
            end if;
            Add(Str => To_String(Health) & To_String(Tired) & To_String(Hungry)
                & To_String(Thirsty));
        end loop;
        if Key /= KEY_NONE then -- Show details about selected crew member
            if (Key >= Key_Code(96 + PlayerShip.Crew.First_Index)) and (Key <= Key_Code(96 + PlayerShip.Crew.Last_Index)) then
                MemberIndex := Integer(Key) - 96;
                for J in PlayerShip.Crew.Element(MemberIndex).Skills'Range loop
                    SkillLevel := To_Unbounded_String("");
                    if PlayerShip.Crew.Element(MemberIndex).Skills(J, 1) > 0 and PlayerShip.Crew.Element(MemberIndex).Skills(J, 1) < 30 then
                        SkillLevel := To_Unbounded_String("Novice");
                    elsif PlayerShip.Crew.Element(MemberIndex).Skills(J, 1) > 31 and PlayerShip.Crew.Element(MemberIndex).Skills(J, 1) < 80 then
                        SkillLevel := To_Unbounded_String("Competent");
                    elsif PlayerShip.Crew.Element(MemberIndex).Skills(J, 1) > 79 then
                        SkillLevel := To_Unbounded_String("Expert");
                    end if;
                    if SkillLevel /= "" then
                        Move_Cursor(Line => Line_Position(2 + J), Column => (Columns / 2));
                        Add(Str => To_String(Skills_Names(J)) & ": " & To_String(SkillLevel));
                    end if;
                end loop;
                case PlayerShip.Crew.Element(MemberIndex).Order is
                    when Duty =>
                        OrderName := To_Unbounded_String("On duty");
                    when Pilot =>
                        OrderName := To_Unbounded_String("Piloting");
                    when Engineer =>
                        OrderName := To_Unbounded_String("Engineering");
                    when Gunner =>
                        OrderName := To_Unbounded_String("Gunner");
                    when Rest =>
                        OrderName := To_Unbounded_String("On break");
                end case;
                Move_Cursor(Line => 8, Column => (Columns / 2));
                Add(Str => "Order: " & To_String(OrderName));
                Change_Attributes(Line => 8, Column => (Columns / 2), Count => 1, Color => 1);
            else
                MemberIndex := 0;
            end if;
        end if;
    end ShowCrewInfo;

    procedure ShowOrdersMenu is
        OrdersWindow : Window;
        OrdersNames : constant array (1..5) of Unbounded_String := (To_Unbounded_String("Duty"), 
            To_Unbounded_String("Piloting"), To_Unbounded_String("Engineering"), 
            To_Unbounded_String("Gunner"), To_Unbounded_String("On break"));
        StartIndex : Integer;
    begin
        OrdersWindow := Create(10, 20, (Lines / 3), (Columns / 3));
        Box(OrdersWindow);
        if MemberIndex = 1 then
            StartIndex := 1;
        else
            StartIndex := 2;
        end if;
        for I in StartIndex..OrdersNames'Last loop
            Move_Cursor(OrdersWindow, Line => Line_Position(I + 1), Column => 5);
            Add(OrdersWindow, Str => To_String(OrdersNames(I)));
            Change_Attributes(OrdersWindow, Line => Line_Position(I + 1), Column => 5, Count => 1, Color => 1);
        end loop;
        Move_Cursor(OrdersWindow, Line => 8, Column => 5);
        Add(OrdersWindow, Str => "Quit");
        Change_Attributes(OrdersWindow, Line => 8, Column => 5, Count => 1, Color => 1);
        Refresh(OrdersWindow);
    end ShowOrdersMenu;
    
    procedure ShowTrade(Key : Key_Code) is
        BaseIndex : constant Positive := SkyMap(PlayerShip.SkyX, PlayerShip.SkyY).BaseIndex;
        BuyLetter, SellLetter : Character;
        BuyLetters : array (SkyBases(BaseIndex).Goods'Range) of Character;
        SellLetters : array (1..PlayerShip.Cargo.Last_Index) of Character := (others => ' ');
        Visibility : Cursor_Visibility := Normal;
        Amount : String(1..6);
        ItemIndex : Natural := 0;
    begin
        if Key /= KEY_NONE then
            Erase;
            Refresh;
            ShowGameMenu(Trade_View);
        end if;
        Move_Cursor(Line => 1, Column => 2);
        Add(Str => "BUY SELL");
        for I in SkyBases(BaseIndex).Goods'Range loop
            if SkyBases(BaseIndex).Goods(I).Buyable then
                BuyLetter := Character'Val(96 + I);
            else
                BuyLetter := ' ';
            end if;
            BuyLetters(I) := BuyLetter;
            SellLetter := ' ';
            for J in PlayerShip.Cargo.First_Index..PlayerShip.Cargo.Last_Index loop
                if PlayerShip.Cargo.Element(J).ProtoIndex = SkyBases(BaseIndex).Goods(I).ProtoIndex then
                    SellLetter := Character'Val(64 + I);
                    SellLetters(J) := SellLetter;
                    exit;
                end if;
            end loop;
            Move_Cursor(Line => Line_Position(1 + I), Column => 3);
            Add(Str => BuyLetter & "   " & SellLetter & "   " &
                To_String(Objects_Prototypes(SkyBases(BaseIndex).Goods(I).ProtoIndex).Name) & " Price:" &
                Positive'Image(SkyBases(BaseIndex).Goods(I).Price) & 
                " charcollum");
        end loop;
        if Key /= KEY_NONE then -- start buying/selling items from/to base
            for I in BuyLetters'Range loop
                if Key = Character'Pos(BuyLetters(I)) and BuyLetters(I) /= ' ' then
                    ItemIndex := I;
                    exit;
                end if;
            end loop;
            if ItemIndex > 0 then -- Buy item from base
                Set_Echo_Mode(True);
                Set_Cursor_Visibility(Visibility);
                Move_Cursor(Line => (Lines / 2), Column => 2);
                Add(Str => "Enter amount to buy: ");
                Get(Str => Amount, Len => 6);
                BuyItems(ItemIndex, Amount);
                ItemIndex := 0;
            else
                for I in SellLetters'Range loop
                    if Key = Character'Pos(SellLetters(I)) and SellLetters(I) /= ' ' then
                        ItemIndex := I;
                        exit;
                    end if;
                end loop;
                if ItemIndex > 0 then -- Sell item to base
                    Set_Echo_Mode(True);
                    Set_Cursor_Visibility(Visibility);
                    Move_Cursor(Line => (Lines / 2), Column => 2);
                    Add(Str => "Enter amount to sell: ");
                    Get(Str => Amount, Len => 6);
                    SellItems(ItemIndex, Amount);
                    ItemIndex := 0;
                end if;
            end if;
            if ItemIndex = 0 then
                Visibility := Invisible;
                Set_Echo_Mode(False);
                Set_Cursor_Visibility(Visibility);
                DrawGame(Trade_View);
            end if;
        end if;
    end ShowTrade;

    procedure ShowHelp is
        Line : Line_Position;
        Column : Column_Position;
    begin
        Move_Cursor(Line => 2, Column => 2);
        Add(Str => "At this moment, help is under heavy developement (as whole game). Below you can find few useful tips.");
        Get_Cursor_Position(Line => Line, Column => Column);
        Move_Cursor(Line => (Line + 1), Column => 2);
        Add(Str => "* Your ship starts docked to base. To move it, you must first undock from base. Hit 'o' key for open orders menu.");
        Get_Cursor_Position(Line => Line, Column => Column);
        Move_Cursor(Line => (Line + 1), Column => 2);
        Add(Str => "* To move your ship, you need to set it speed, have fuel (charcollum, which works as moneys too) and pilot and engineer on duty.");
        Get_Cursor_Position(Line => Line, Column => Column);
        Move_Cursor(Line => (Line + 1), Column => 2);
        Add(Str => "* To buy/sell items from bases you must first dock to base. All bases buy all items, but which items are sold, depends on base type.");
        Get_Cursor_Position(Line => Line, Column => Column);
        Move_Cursor(Line => (Line + 1), Column => 2);
        Add(Str => "* As you dock to stations, you discover they types and then they will be colored on sky map (eg. Agricultural bases are green). Unvisited bases are white. ");
    end ShowHelp;

    procedure DrawGame(CurrentState : GameStates) is
    begin
        Erase;
        Refresh;
        ShowGameMenu(CurrentState);
        case CurrentState is
            when Sky_Map_View =>
                ShowSkyMap;
            when Control_Speed =>
                ShowSpeedControl;
            when Ship_Info =>
                ShowShipInfo;
            when Crew_Info =>
                ShowCrewInfo(KEY_NONE);
            when Giving_Orders =>
                ShowOrdersMenu;
            when Messages_View =>
                ShowMessages;
            when Trade_View =>
                ShowTrade(KEY_NONE);
            when Help_View =>
                ShowHelp;
            when others =>
                null;
        end case;
    end DrawGame;

    function MainMenuKeys(Key : Key_Code) return GameStates is
    begin
        case Key is
            when Character'Pos('q') | Character'Pos('Q') => -- Quit game
                return Quit;
            when Character'Pos('n') | Character'Pos('N') => -- New game
                -- Start new game
                NewGame;
                DrawGame(Sky_Map_View);
                return Sky_Map_View;
            when Character'Pos('l') | Character'Pos('L') => -- Load game
                if Exists("data/savegame.dat") then
                    LoadGame;
                    DrawGame(Sky_Map_View);
                    return Sky_Map_View;
                else
                    return Main_Menu;
                end if;
            when others => 
                return Main_Menu;
        end case;
    end MainMenuKeys;
    
    function GameMenuKeys(CurrentState : GameStates; Key : Key_Code) return GameStates is
    begin
        case Key is
            when Character'Pos('q') | Character'Pos('Q') => -- Back to main menu
                SaveGame;
                ClearMessages;
                Erase;
                Refresh;
                ShowMainMenu;
                return Main_Menu;
            when Character'Pos('s') | Character'Pos('S') => -- Ship info screen
                DrawGame(Ship_Info);
                return Ship_Info;
            when Character'Pos('c') | Character'Pos('C') => -- Crew info screen
                DrawGame(Crew_Info);
                return Crew_Info;
            when Character'Pos('m') | Character'Pos('M') => -- Messages list screen
                DrawGame(Messages_View);
                return Messages_View;
            when Character'Pos('h') | Character'Pos('H') => -- Help screen
                DrawGame(Help_View);
                return Help_View;
            when others =>
                return CurrentState;
        end case;
    end GameMenuKeys;

    function SpeedMenuKeys(OldState : GameStates; Key : Key_Code) return GameStates is
    begin
        case Key is
            when Character'Pos('q') | Character'Pos('Q') => -- Back to sky map
                DrawGame(Sky_Map_View);
                return OldState;
            when Character'Pos('t') | Character'Pos('T') => -- Trade with base
                if PlayerShip.Speed = DOCKED then
                    DrawGame(Trade_View);
                    return Trade_View;
                else
                    return Control_Speed;
                end if;
            when Character'Pos('u') | Character'Pos('U') => -- Undock ship from base
                DockShip(False);
                DrawGame(Sky_Map_View);
                return OldState;
            when Character'Pos('d') | Character'Pos('D') => -- Dock ship to base
                DockShip(True);
                DrawGame(Sky_Map_View);
                return OldState;
            when Character'Pos('f') | Character'Pos('F') => -- Full stop
                ChangeShipSpeed(FULL_STOP);
                DrawGame(Sky_Map_View);
                return OldState;
            when Character'Pos('a') | Character'Pos('A') => -- Quarter speed
                ChangeShipSpeed(QUARTER_SPEED);
                DrawGame(Sky_Map_View);
                return OldState;
            when Character'Pos('h') | Character'Pos('H') => -- Half speed
                ChangeShipSpeed(HALF_SPEED);
                DrawGame(Sky_Map_View);
                return OldState;
            when Character'Pos('l') | Character'Pos('L') => -- Full speed
                ChangeShipSpeed(FULL_SPEED);
                DrawGame(Sky_Map_View);
                return OldState;
            when others =>
                return Control_Speed;
        end case;
    end SpeedMenuKeys;

    function ShipInfoKeys(Key : Key_Code) return GameStates is
    begin
        case Key is
            when Character'Pos('q') | Character'Pos('Q') => -- Back to sky map
                DrawGame(Sky_Map_View);
                return Sky_Map_View;
            when others =>
                return Ship_Info;
        end case;
    end ShipInfoKeys;

    function CrewInfoKeys(Key : Key_Code) return GameStates is
    begin
        case Key is
            when Character'Pos('q') | Character'Pos('Q') => -- Back to sky map
                DrawGame(Sky_Map_View);
                return Sky_Map_View;
            when Character'Pos('o') | Character'Pos('O') => -- Give orders to selected crew member
                if MemberIndex > 0 then
                    DrawGame(Giving_Orders);
                    return Giving_Orders;
                else
                    ShowCrewInfo(Key);
                    return Crew_Info;
                end if;
            when others =>
                ShowCrewInfo(Key);
                return Crew_Info;
        end case;
    end CrewInfoKeys;

    function CrewOrdersKeys(Key : Key_Code) return GameStates is
    begin
        case Key is
            when Character'Pos('q') | Character'Pos('Q') => -- Back to crew info
                MemberIndex := 0;
                DrawGame(Crew_Info);
                return Crew_Info;
            when Character'Pos('d') | Character'Pos('D') => -- Give order on duty
                GiveOrders(MemberIndex, Duty);
                MemberIndex := 0;
                DrawGame(Crew_Info);
                return Crew_Info;
            when Character'Pos('p') | Character'Pos('P') => -- Give order piloting
                GiveOrders(MemberIndex, Pilot);
                MemberIndex := 0;
                DrawGame(Crew_Info);
                return Crew_Info;
            when Character'Pos('e') | Character'Pos('E') => -- Give order engineering
                GiveOrders(MemberIndex, Engineer);
                MemberIndex := 0;
                DrawGame(Crew_Info);
                return Crew_Info;
            when Character'Pos('g') | Character'Pos('G') => -- Give order gunnery
                GiveOrders(MemberIndex, Gunner);
                MemberIndex := 0;
                DrawGame(Crew_Info);
                return Crew_Info;
            when Character'Pos('o') | Character'Pos('O') => -- Give order rest
                GiveOrders(MemberIndex, Rest);
                MemberIndex := 0;
                DrawGame(Crew_Info);
                return Crew_Info;
            when others =>
                return Giving_Orders;
        end case;
    end CrewOrdersKeys;

    function TradeKeys(Key : Key_Code) return GameStates is
    begin
        case Key is
            when Character'Pos('q') | Character'Pos('Q') => -- Back to sky map
                DrawGame(Sky_Map_View);
                return Sky_Map_View;
            when others =>
                ShowTrade(Key);
                return Trade_View;
        end case;
    end TradeKeys;

    function HelpKeys(Key : Key_Code) return GameStates is
    begin
        case Key is
            when Character'Pos('q') | Character'Pos('Q') => -- Back to sky map
                DrawGame(Sky_Map_View);
                return Sky_Map_View;
            when others =>
                ShowHelp;
                return Help_View;
        end case;
    end HelpKeys;

end UserInterface;
