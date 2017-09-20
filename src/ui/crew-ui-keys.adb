--    Copyright 2017 Bartek thindil Jasicki
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

with Ada.Exceptions; use Ada.Exceptions;
with Terminal_Interface.Curses.Menus; use Terminal_Interface.Curses.Menus;
with UserInterface; use UserInterface;
with Ships; use Ships;
with Ships.Cargo; use Ships.Cargo;
with ShipModules; use ShipModules;
with Help.UI; use Help.UI;
with Header; use Header;
with Utils.UI; use Utils.UI;

package body Crew.UI.Keys is

   function MoveItemResult return GameStates is
      FieldIndex: constant Positive := Get_Index(Current(MoveForm));
      ItemIndex: constant Positive := Get_Index(Current(CrewMenu));
      Item: constant InventoryData :=
        PlayerShip.Crew(MemberIndex).Inventory(ItemIndex);
      Visibility: Cursor_Visibility := Invisible;
   begin
      if FieldIndex = 3 or
        Get_Buffer(Fields(MoveForm, 2)) = "                    " then
         Set_Cursor_Visibility(Visibility);
         Post(MoveForm, False);
         Delete(MoveForm);
         DrawGame(Inventory_View);
         return Inventory_View;
      end if;
      UpdateCargo
        (PlayerShip,
         Item.ProtoIndex,
         Integer'Value(Get_Buffer(Fields(MoveForm, 2))),
         Item.Durability);
      UpdateInventory
        (MemberIndex => MemberIndex,
         Amount => (0 - Integer'Value(Get_Buffer(Fields(MoveForm, 2)))),
         InventoryIndex => ItemIndex);
      if
        (PlayerShip.Crew(MemberIndex).Order = Clean and
         FindItem
             (Inventory => PlayerShip.Crew(MemberIndex).Inventory,
              ItemType => CleaningTools) =
           0) or
        ((PlayerShip.Crew(MemberIndex).Order = Upgrading or
          PlayerShip.Crew(MemberIndex).Order = Repair) and
         FindItem
             (Inventory => PlayerShip.Crew(MemberIndex).Inventory,
              ItemType => RepairTools) =
           0) then
         GiveOrders(MemberIndex, Rest);
      end if;
      Post(MoveForm, False);
      Delete(MoveForm);
      DrawGame(Inventory_View);
      return Inventory_View;
   end MoveItemResult;

   function CrewInfoKeys
     (Key: Key_Code;
      OldState: GameStates) return GameStates is
      Result: Menus.Driver_Result;
      RefreshSkills: Boolean := False;
   begin
      case Key is
         when 27 => -- Back to sky map or combat screen
            MemberIndex := 1;
            NeedRepairs := False;
            NeedClean := False;
            DrawGame(OldState);
            return OldState;
         when 56 | KEY_UP => -- Select previous crew member
            Result := Driver(CrewMenu, M_Up_Item);
            if Result = Request_Denied then
               Result := Driver(CrewMenu, M_Last_Item);
            end if;
         when 50 | KEY_DOWN => -- Select next crew member
            Result := Driver(CrewMenu, M_Down_Item);
            if Result = Request_Denied then
               Result := Driver(CrewMenu, M_First_Item);
            end if;
         when 51 | KEY_NPAGE => -- Scroll skills one line down
            StartIndex := StartIndex + 1;
            RefreshSkills := True;
         when 57 | KEY_PPAGE => -- Scroll skills one line up
            StartIndex := StartIndex - 1;
            RefreshSkills := True;
         when 10 => -- Give orders to selected crew member
            ShowOrdersMenu;
            return Giving_Orders;
         when 32 => -- Give orders to all crew
            if NeedRepairs or NeedClean then
               ShowOrdersForAll;
               return Orders_For_All;
            end if;
         when Key_F1 => -- Show help
            Erase;
            ShowGameHeader(Help_Topic);
            ShowHelp(Crew_Info, 7);
            return Help_Topic;
         when Key_F2 => -- Show crew member inventory
            DrawGame(Inventory_View);
            return Inventory_View;
         when others =>
            Result := Driver(CrewMenu, Key);
            if Result /= Menu_Ok then
               Result := Driver(CrewMenu, M_Clear_Pattern);
               Result := Driver(CrewMenu, Key);
            end if;
      end case;
      if Result = Menu_Ok then
         MemberIndex := Get_Index(Current(CrewMenu));
         ShowMemberInfo;
      end if;
      if StartIndex < 0 then
         StartIndex := 0;
      end if;
      if StartIndex > EndIndex then
         StartIndex := EndIndex;
      end if;
      if RefreshSkills then
         ShowMemberInfo;
      end if;
      return Crew_Info;
   end CrewInfoKeys;

   function CrewOrdersKeys(Key: Key_Code) return GameStates is
      Result: Menus.Driver_Result;
      ModuleIndex: constant Natural :=
        Natural'Value(Description(Current(OrdersMenu)));
      OrderName: constant String := Name(Current(OrdersMenu));
   begin
      case Key is
         when 56 | KEY_UP => -- Select previous order
            Result := Driver(OrdersMenu, M_Up_Item);
            if Result = Request_Denied then
               Result := Driver(OrdersMenu, M_Last_Item);
            end if;
         when 50 | KEY_DOWN => -- Select next order
            Result := Driver(OrdersMenu, M_Down_Item);
            if Result = Request_Denied then
               Result := Driver(OrdersMenu, M_First_Item);
            end if;
         when 10 => -- Select order
            if OrderName = "Piloting" then
               GiveOrders(MemberIndex, Pilot);
            elsif OrderName = "Engineering" then
               GiveOrders(MemberIndex, Engineer);
            elsif OrderName = "Go on break" then
               GiveOrders(MemberIndex, Rest);
            elsif OrderName = "Repair ship" then
               GiveOrders(MemberIndex, Repair);
            elsif OrderName = "Upgrade module" then
               GiveOrders(MemberIndex, Upgrading);
            elsif OrderName = "Talking in bases" then
               GiveOrders(MemberIndex, Talk);
            elsif OrderName = "Heal wounded crew members" then
               GiveOrders(MemberIndex, Heal, ModuleIndex);
            elsif OrderName = "Clean ship" then
               GiveOrders(MemberIndex, Clean);
            elsif OrderName = "Dismiss" then
               DrawGame(Dismiss_Confirm);
               return Dismiss_Confirm;
            elsif OrderName = "Set orders priorities" then
               DrawGame(Crew_Info);
               ShowPrioritiesMenu;
               return Orders_Priorities;
            elsif OrderName /= "Close" then
               if Modules_List(PlayerShip.Modules(ModuleIndex).ProtoIndex)
                   .MType =
                 GUN then
                  GiveOrders(MemberIndex, Gunner, ModuleIndex);
               else
                  GiveOrders(MemberIndex, Craft, ModuleIndex);
               end if;
            end if;
            DrawGame(Crew_Info);
            return Crew_Info;
         when 27 => -- Esc select close option, used second time, close menu
            if OrderName = "Close" then
               DrawGame(Crew_Info);
               return Crew_Info;
            else
               Result := Driver(OrdersMenu, M_Last_Item);
            end if;
         when others =>
            Result := Driver(OrdersMenu, Key);
            if Result /= Menu_Ok then
               Result := Driver(OrdersMenu, M_Clear_Pattern);
               Result := Driver(OrdersMenu, Key);
            end if;
      end case;
      if Result = Menu_Ok then
         Refresh(MenuWindow2);
      end if;
      return Giving_Orders;
   exception
      when An_Exception : Crew_Order_Error =>
         ShowDialog(Exception_Message(An_Exception));
         DrawGame(Crew_Info);
         return Crew_Info;
   end CrewOrdersKeys;

   function CrewOrdersAllKeys(Key: Key_Code) return GameStates is
      Result: Menus.Driver_Result;
      OrderName: constant String := Name(Current(OrdersMenu));
   begin
      case Key is
         when 56 | KEY_UP => -- Select previous order
            Result := Driver(OrdersMenu, M_Up_Item);
            if Result = Request_Denied then
               Result := Driver(OrdersMenu, M_Last_Item);
            end if;
         when 50 | KEY_DOWN => -- Select next order
            Result := Driver(OrdersMenu, M_Down_Item);
            if Result = Request_Denied then
               Result := Driver(OrdersMenu, M_First_Item);
            end if;
         when 10 => -- Select order
            if OrderName = "Repair ship everyone" then
               for I in
                 PlayerShip.Crew.First_Index .. PlayerShip.Crew.Last_Index loop
                  if PlayerShip.Crew(I).Skills.Length > 0 then
                     GiveOrders(I, Repair);
                  end if;
               end loop;
            elsif OrderName = "Clean ship everyone" then
               for I in
                 PlayerShip.Crew.First_Index .. PlayerShip.Crew.Last_Index loop
                  if PlayerShip.Crew(I).Skills.Length > 0 then
                     GiveOrders(I, Clean);
                  end if;
               end loop;
            end if;
            DrawGame(Crew_Info);
            return Crew_Info;
         when 27 => -- Esc select close option, used second time, close menu
            if OrderName = "Close" then
               DrawGame(Crew_Info);
               return Crew_Info;
            else
               Result := Driver(OrdersMenu, M_Last_Item);
            end if;
         when others =>
            Result := Driver(OrdersMenu, Key);
            if Result /= Menu_Ok then
               Result := Driver(OrdersMenu, M_Clear_Pattern);
               Result := Driver(OrdersMenu, Key);
            end if;
      end case;
      if Result = Menu_Ok then
         Refresh(MenuWindow2);
      end if;
      return Orders_For_All;
   exception
      when An_Exception : Crew_Order_Error | Crew_No_Space_Error =>
         ShowDialog(Exception_Message(An_Exception));
         DrawGame(Crew_Info);
         return Crew_Info;
   end CrewOrdersAllKeys;

   function OrdersPrioritiesKeys(Key: Key_Code) return GameStates is
      Result: Menus.Driver_Result;
      OptionIndex: Positive := PriorityIndex;
      NewPriority: Integer := -1;
   begin
      case Key is
         when 56 | KEY_UP => -- Select previous order
            Result := Driver(PrioritiesMenu, M_Up_Item);
            if Result = Request_Denied then
               Result := Driver(PrioritiesMenu, M_Last_Item);
            end if;
         when 50 | KEY_DOWN => -- Select next order
            Result := Driver(PrioritiesMenu, M_Down_Item);
            if Result = Request_Denied then
               Result := Driver(PrioritiesMenu, M_First_Item);
            end if;
         when 52 | KEY_LEFT => -- Set lower priority
            NewPriority :=
              PlayerShip.Crew(MemberIndex).Orders(OptionIndex) - 1;
            if NewPriority > -1 then
               DrawGame(Crew_Info);
               PlayerShip.Crew(MemberIndex).Orders(OptionIndex) := NewPriority;
            end if;
         when 54 | KEY_RIGHT => -- Set higher priority
            NewPriority :=
              PlayerShip.Crew(MemberIndex).Orders(OptionIndex) + 1;
            if NewPriority = 1 then
               DrawGame(Crew_Info);
               PlayerShip.Crew(MemberIndex).Orders(OptionIndex) := NewPriority;
            elsif NewPriority = 2 then
               DrawGame(Crew_Info);
               for I in PlayerShip.Crew.Element(MemberIndex).Orders'Range loop
                  if PlayerShip.Crew(MemberIndex).Orders(I) = 2 then
                     NewPriority := 1;
                     OptionIndex := I;
                     PlayerShip.Crew(MemberIndex).Orders(OptionIndex) :=
                       NewPriority;
                     exit;
                  end if;
               end loop;
               NewPriority := 2;
               OptionIndex := Get_Index(Current(PrioritiesMenu));
               PlayerShip.Crew(MemberIndex).Orders(OptionIndex) := NewPriority;
            else
               NewPriority := -1;
            end if;
         when 10 => -- Quit or show hint about setting
            if OptionIndex > Orders_Array'Last then
               PriorityIndex := 1;
               UpdateOrders;
               DrawGame(Crew_Info);
               return Crew_Info;
            else
               ShowDialog
                 ("Use Left arrow to lower order priority or Right arrow to raise order priority.");
               DrawGame(Crew_Info);
               ShowPrioritiesMenu;
            end if;
         when 27 => -- Esc select close option, used second time, close menu
            if Name(Current(PrioritiesMenu)) = "Close" then
               DrawGame(Crew_Info);
               return Crew_Info;
            else
               Result := Driver(PrioritiesMenu, M_Last_Item);
            end if;
         when others =>
            Result := Driver(PrioritiesMenu, Key);
            if Result /= Menu_Ok then
               Result := Driver(PrioritiesMenu, M_Clear_Pattern);
               Result := Driver(PrioritiesMenu, Key);
            end if;
      end case;
      if Result = Menu_Ok then
         PriorityIndex := Get_Index(Current(PrioritiesMenu));
         Refresh(MenuWindow2);
      end if;
      if NewPriority > -1 then
         ShowPrioritiesMenu;
      end if;
      return Orders_Priorities;
   end OrdersPrioritiesKeys;

   function InventoryKeys(Key: Key_Code) return GameStates is
      Result: Menus.Driver_Result;
   begin
      if PlayerShip.Crew(MemberIndex).Inventory.Length = 0 then
         if Key = 27 then -- back to crew info
            DrawGame(Crew_Info);
            return Crew_Info;
         end if;
         return Inventory_View;
      end if;
      case Key is
         when 27 => -- back to crew info
            DrawGame(Crew_Info);
            return Crew_Info;
         when 56 | KEY_UP => -- Select previous item in inventory
            Result := Driver(CrewMenu, M_Up_Item);
            if Result = Request_Denied then
               Result := Driver(CrewMenu, M_Last_Item);
            end if;
         when 50 | KEY_DOWN => -- Select next item in inventory
            Result := Driver(CrewMenu, M_Down_Item);
            if Result = Request_Denied then
               Result := Driver(CrewMenu, M_First_Item);
            end if;
         when 10 => -- Move item to ship cargo
            ShowMoveForm;
            return MoveItem_Form;
         when others =>
            Result := Driver(CrewMenu, Key);
            if Result /= Menu_Ok then
               Result := Driver(CrewMenu, M_Clear_Pattern);
               Result := Driver(CrewMenu, Key);
            end if;
      end case;
      if Result = Menu_Ok then
         ShowItemInfo;
      end if;
      return Inventory_View;
   end InventoryKeys;

   function MoveItemFormKeys(Key: Key_Code) return GameStates is
      Result: Forms.Driver_Result;
      FieldIndex: Positive := Get_Index(Current(MoveForm));
      Visibility: Cursor_Visibility := Invisible;
   begin
      case Key is
         when KEY_UP => -- Select previous field
            Result := Driver(MoveForm, F_Previous_Field);
            FieldIndex := Get_Index(Current(MoveForm));
            if FieldIndex = 2 then
               Result := Driver(MoveForm, F_End_Line);
            end if;
         when KEY_DOWN => -- Select next field
            Result := Driver(MoveForm, F_Next_Field);
            FieldIndex := Get_Index(Current(MoveForm));
            if FieldIndex = 2 then
               Result := Driver(MoveForm, F_End_Line);
            end if;
         when 10 => -- quit/move item
            if FieldIndex = 2 then
               Result := Driver(MoveForm, F_Next_Field);
               if Result = Form_Ok then
                  if Get_Buffer(Fields(MoveForm, 2)) =
                    "                    " then
                     FieldIndex := 3;
                  else
                     FieldIndex := 4;
                  end if;
                  Set_Current(MoveForm, Fields(MoveForm, FieldIndex));
               end if;
            else
               return MoveItemResult;
            end if;
         when Key_Backspace => -- delete last character
            if FieldIndex = 2 then
               Result := Driver(MoveForm, F_Delete_Previous);
               if Result = Form_Ok then
                  FieldIndex := Get_Index(Current(MoveForm));
                  if FieldIndex /= 2 then
                     FieldIndex := 2;
                     Set_Current(MoveForm, Fields(MoveForm, 2));
                  end if;
               end if;
            end if;
         when KEY_DC => -- delete character at cursor
            if FieldIndex = 2 then
               Result := Driver(MoveForm, F_Delete_Char);
            end if;
         when KEY_RIGHT => -- Move cursor right
            if FieldIndex = 2 then
               Result := Driver(MoveForm, F_Right_Char);
            end if;
         when KEY_LEFT => -- Move cursor left
            if FieldIndex = 2 then
               Result := Driver(MoveForm, F_Left_Char);
            end if;
         when 27 => -- Escape select cancel button, second time closes form
            if FieldIndex /= 3 then
               FieldIndex := 3;
               Set_Current(MoveForm, Fields(MoveForm, 3));
               Result := Form_Ok;
            else
               Post(MoveForm, False);
               Delete(MoveForm);
               DrawGame(Inventory_View);
               return Inventory_View;
            end if;
         when others =>
            Result := Driver(MoveForm, Key);
      end case;
      if Result = Form_Ok then
         for I in 2 .. 4 loop
            Set_Foreground(Fields(MoveForm, I));
            Set_Background(Fields(MoveForm, I));
         end loop;
         Set_Foreground(Current(MoveForm), BoldCharacters, 11);
         Set_Background(Current(MoveForm), BoldCharacters, 11);
         if FieldIndex = 2 then
            Visibility := Normal;
         end if;
         Set_Cursor_Visibility(Visibility);
         Refresh(FormWindow);
      end if;
      return MoveItem_Form;
   end MoveItemFormKeys;

end Crew.UI.Keys;