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

with Ships; use Ships;
with Messages; use Messages;
with UserInterface; use UserInterface;

package body Crew is

    MemberIndex : Natural;

    procedure GiveOrders(MemberIndex : Positive; GivenOrder : Crew_Orders) is
        NewOrder : Crew_Orders;
        procedure UpdateOrder(Member : in out Member_Data) is
        begin
            Member.Order := NewOrder;
        end UpdateOrder;
    begin
        if GivenOrder = PlayerShip.Crew.Element(MemberIndex).Order then
            return;
        end if;
        if GivenOrder = Duty and MemberIndex > 1 then
            ShowDialog("Only you can go on duty.");
            return;
        end if;
        for I in PlayerShip.Crew.First_Index..PlayerShip.Crew.Last_Index loop
            if PlayerShip.Crew.Element(I).Order = GivenOrder then
                NewOrder := Rest;
                PlayerShip.Crew.Update_Element(Index => I, Process => UpdateOrder'Access);
                AddMessage(To_String(PlayerShip.Crew.Element(I).Name) & " going on break.");
            end if;
        end loop;
        NewOrder := GivenOrder;
        PlayerShip.Crew.Update_Element(Index => MemberIndex, Process => UpdateOrder'Access);
        case GivenOrder is
            when Duty =>
                AddMessage(To_String(PlayerShip.Crew.Element(MemberIndex).Name) & " back on duty.");
            when Pilot =>
                AddMessage(To_String(PlayerShip.Crew.Element(MemberIndex).Name) & " starts piloting.");
            when Engineer =>
                AddMessage(To_String(PlayerShip.Crew.Element(MemberIndex).Name) & " starts engineers duty.");
            when Gunner =>
                AddMessage(To_String(PlayerShip.Crew.Element(MemberIndex).Name) & " starts operating gun.");
            when Rest =>
                AddMessage(To_String(PlayerShip.Crew.Element(MemberIndex).Name) & " going on break.");
        end case;
    end GiveOrders;

    procedure ShowCrewInfo(Key : Key_Code) is
        Health, Tired, Hungry, Thirsty, SkillLevel, OrderName : Unbounded_String;
        Skills_Names : constant array (1..4) of Unbounded_String := (To_Unbounded_String("Piloting"), 
            To_Unbounded_String("Engineering"), To_Unbounded_String("Gunnery"), 
            To_Unbounded_String("Bartering"));
        SkillLine : Line_Position := 3;
    begin
        if Key /= KEY_NONE then
            Erase;
            Refresh;
            ShowGameMenu(Crew_Info);
        end if;
        for I in PlayerShip.Crew.First_Index..PlayerShip.Crew.Last_Index loop
            Move_Cursor(Line => Line_Position(2 + I), Column => 2);
            Add(Str => Character'Val(96 + I) & " " & To_String(PlayerShip.Crew.Element(I).Name));
            if PlayerShip.Crew.Element(I).Health = 100 then
                Health := To_Unbounded_String("");
            elsif PlayerShip.Crew.Element(I).Health < 100 and PlayerShip.Crew.Element(I).Health > 50 then
                Health := To_Unbounded_String(" [Wounded]");
            elsif PlayerShip.Crew.Element(I).Health < 51 and PlayerShip.Crew.Element(I).Health > 0 then
                Health := To_Unbounded_String(" [Heavily Wounded]");
            else
                Health := To_Unbounded_String(" [Dead]");
            end if;
            if PlayerShip.Crew.Element(I).Tired < 41 then
                Tired := To_Unbounded_String("");
            elsif PlayerShip.Crew.Element(I).Tired > 40 and PlayerShip.Crew(I).Tired < 81 then
                Tired := To_Unbounded_String(" [Tired]");
            elsif PlayerShip.Crew.Element(I).Tired > 80 and PlayerShip.Crew(I).Tired < 100 then
                Tired := To_Unbounded_String(" [Very tired]");
            else
                Tired := To_Unbounded_String(" [Unconscious]");
            end if;
            if PlayerShip.Crew.Element(I).Hunger < 41 then
                Hungry := To_Unbounded_String("");
            elsif PlayerShip.Crew.Element(I).Hunger > 40 and PlayerShip.Crew(I).Hunger < 81 then
                Hungry := To_Unbounded_String(" [Hungry]");
            elsif PlayerShip.Crew.Element(I).Hunger > 80 and PlayerShip.Crew(I).Hunger < 100 then
                Hungry := To_Unbounded_String(" [Very hungry]");
            else
                Hungry := To_Unbounded_String(" [Starving]");
            end if;
            if PlayerShip.Crew.Element(I).Thirst < 40 then
                Thirsty := To_Unbounded_String("");
            elsif PlayerShip.Crew.Element(I).Thirst > 40 and PlayerShip.Crew(I).Thirst < 81 then
                Thirsty := To_Unbounded_String(" [Thirsty]");
            elsif PlayerShip.Crew.Element(I).Thirst > 80 and PlayerShip.Crew(I).Thirst < 100 then
                Thirsty := To_Unbounded_String(" [Very thirsty]");
            else
                Thirsty := To_Unbounded_String(" [Dehydrated]");
            end if;
            Add(Str => To_String(Health) & To_String(Tired) & To_String(Hungry)
                & To_String(Thirsty));
            Change_Attributes(Line => Line_Position(2 + I), Column => 2, Count => 1, Color => 1);
        end loop;
        if Key /= KEY_NONE then -- Show details about selected crew member
            if (Key >= Key_Code(96 + PlayerShip.Crew.First_Index)) and (Key <= Key_Code(96 + PlayerShip.Crew.Last_Index)) then
                MemberIndex := Integer(Key) - 96;
                Move_Cursor(Line => 2, Column => (Columns / 2));
                Add(Str => "Name: " & To_String(PlayerShip.Crew.Element(MemberIndex).Name));
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
                        Move_Cursor(Line => SkillLine, Column => (Columns / 2));
                        Add(Str => To_String(Skills_Names(J)) & ": " & To_String(SkillLevel));
                        SkillLine := SkillLine + 1;
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
        OrdersWindow := Create(10, 20, (Lines / 2) - 5, (Columns / 2) - 10);
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

    function CrewInfoKeys(Key : Key_Code) return GameStates is
    begin
        case Key is
            when Character'Pos('q') | Character'Pos('Q') => -- Back to sky map
                DrawGame(Sky_Map_View);
                return Sky_Map_View;
            when Character'Pos('o') | Character'Pos('O') => -- Give orders to selected crew member
                if MemberIndex > 0 then
                    ShowCrewInfo(Key_Code(MemberIndex + 96));
                    Refresh_Without_Update;
                    ShowOrdersMenu;
                    Update_Screen;
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

end Crew;
