--    Copyright 2018 Bartek thindil Jasicki
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
with Ada.Containers; use Ada.Containers;
with Gtk.Window; use Gtk.Window;
with Gtk.Label; use Gtk.Label;
with Gtk.Combo_Box; use Gtk.Combo_Box;
with Gtk.Text_Buffer; use Gtk.Text_Buffer;
with Gtk.Text_Iter; use Gtk.Text_Iter;
with Gtk.Text_Tag; use Gtk.Text_Tag;
with Gtk.Text_View; use Gtk.Text_View;
with Gtk.Button; use Gtk.Button;
with Gtk.Enums; use Gtk.Enums;
with Gtk.Container; use Gtk.Container;
with Gtk.Adjustment; use Gtk.Adjustment;
with Gtk.Stack; use Gtk.Stack;
with Glib; use Glib;
with Gdk; use Gdk;
with Gdk.Rectangle; use Gdk.Rectangle;
with Gdk.Device; use Gdk.Device;
with Gdk.Window; use Gdk.Window;
with Game; use Game;
with Utils; use Utils;
with Utils.UI; use Utils.UI;
with Ships.UI; use Ships.UI;
with Ships.Movement; use Ships.Movement;
with Ships.Crew; use Ships.Crew;
with Ships.Cargo; use Ships.Cargo;
with Ships.Cargo.UI; use Ships.Cargo.UI;
with Messages; use Messages;
with Messages.UI; use Messages.UI;
with Crew; use Crew;
with Crew.UI; use Crew.UI;
with ShipModules; use ShipModules;
with Events; use Events;
with Events.UI; use Events.UI;
with Items; use Items;
with Config; use Config;
with Bases; use Bases;
with Bases.UI; use Bases.UI;
with Bases.SchoolUI; use Bases.SchoolUI;
with Bases.ShipyardUI; use Bases.ShipyardUI;
with Bases.LootUI; use Bases.LootUI;
with Missions; use Missions;
with Missions.UI; use Missions.UI;
with Crafts; use Crafts;
with Combat; use Combat;
with Combat.UI; use Combat.UI;
with Help.UI; use Help.UI;
with Statistics.UI; use Statistics.UI;
with Trades; use Trades;
with Trades.UI; use Trades.UI;
with Crafts.UI; use Crafts.UI;
with BasesList; use BasesList;
with GameOptions; use GameOptions;

package body Maps.UI.Handlers is

   procedure QuitGameMenu(Object: access Gtkada_Builder_Record'Class) is
   begin
      if not QuitGame(Gtk_Window(Get_Object(Object, "skymapwindow"))) then
         ShowDialog
           ("Can't quit game.",
            Gtk_Window(Get_Object(Object, "skymapwindow")));
      end if;
   end QuitGameMenu;

   procedure HideMapInfoWindow(User_Data: access GObject_Record'Class) is
   begin
      Hide(Gtk_Window(User_Data));
   end HideMapInfoWindow;

   procedure GetMapSize(Object: access Gtkada_Builder_Record'Class) is
      MapBuffer: constant Gtk_Text_Buffer :=
        Gtk_Text_Buffer(Get_Object(Object, "txtmap"));
      MapView: constant Gtk_Text_View :=
        Gtk_Text_View(Get_Object(Object, "mapview"));
      Iter: Gtk_Text_Iter;
      Location: Gdk_Rectangle;
      Result: Boolean;
   begin
      Get_Start_Iter(MapBuffer, Iter);
      Forward_Line(Iter, Result);
      Forward_Char(Iter, Result);
      Get_Iter_Location(MapView, Iter, Location);
      if Location.Y = 0 then
         return;
      end if;
      if (Get_Allocated_Height(Gtk_Widget(MapView)) / Location.Y) - 1 < 1 then
         return;
      end if;
      MapWidth :=
        Positive(Get_Allocated_Width(Gtk_Widget(MapView)) / Location.X) - 1;
      MapHeight :=
        Positive(Get_Allocated_Height(Gtk_Widget(MapView)) / Location.Y) - 1;
      MapCellWidth := Positive(Location.X);
      MapCellHeight := Positive(Location.Y);
      Set_Text(MapBuffer, "");
      DrawMap;
      Get_Size
        (Gtk_Window(Get_Object(Object, "skymapwindow")),
         Gint(GameSettings.WindowWidth),
         Gint(GameSettings.WindowHeight));
   end GetMapSize;

   function ShowMapCellInfo
     (Object: access Gtkada_Builder_Record'Class) return Boolean is
      MapInfoText: Unbounded_String;
   begin
      GetCurrentCellCoords;
      if MapX = PlayerShip.SkyX and MapY = PlayerShip.SkyY then
         ShowOrders(Object);
         return True;
      end if;
      Set_Label
        (Gtk_Label(Get_Object(Object, "lblmapx")),
         "X:" & Positive'Image(MapX));
      Set_Label
        (Gtk_Label(Get_Object(Object, "lblmapy")),
         "Y:" & Positive'Image(MapY));
      BuildMapInfo(MapInfoText);
      if MapX /= PlayerShip.SkyX or MapY /= PlayerShip.SkyY then
         Set_Sensitive(Gtk_Widget(Get_Object(Object, "btndestination")));
         if Length(MapInfoText) > 0 then
            Append(MapInfoText, ASCII.LF);
         end if;
         Append
           (MapInfoText,
            "Distance:" & Positive'Image(CountDistance(MapX, MapY)));
      else
         Set_Sensitive
           (Gtk_Widget(Get_Object(Object, "btndestination")),
            False);
      end if;
      Set_Label
        (Gtk_Label(Get_Object(Object, "lblmapinfo")),
         To_String(MapInfoText));
      Show_All(Gtk_Widget(Get_Object(Builder, "mapinfowindow")));
      return True;
   end ShowMapCellInfo;

   procedure SetDestination(Object: access Gtkada_Builder_Record'Class) is
   begin
      PlayerShip.DestinationX := MapX;
      PlayerShip.DestinationY := MapY;
      AddMessage("You set travel destination for your ship.", OrderMessage);
      Hide(Gtk_Window(Get_Object(Object, "mapinfowindow")));
      UpdateMessages;
      UpdateMoveButtons;
   end SetDestination;

   procedure MoveMap(User_Data: access GObject_Record'Class) is
   begin
      if User_Data = Get_Object(Builder, "btncenter") then
         CenterX := PlayerShip.SkyX;
         CenterY := PlayerShip.SkyY;
      elsif User_Data = Get_Object(Builder, "btnmovemapok") then
         CenterX :=
           Positive(Get_Value(Gtk_Adjustment(Get_Object(Builder, "mapxadj"))));
         CenterY :=
           Positive(Get_Value(Gtk_Adjustment(Get_Object(Builder, "mapyadj"))));
      elsif User_Data = Get_Object(Builder, "btnmapup") then
         if CenterY - (MapHeight / 3) < 1 then
            CenterY := 1;
         else
            CenterY := CenterY - (MapHeight / 3);
         end if;
      elsif User_Data = Get_Object(Builder, "btnmapdown") then
         if CenterY + (MapHeight / 3) > 1024 then
            CenterY := 1024;
         else
            CenterY := CenterY + (MapHeight / 3);
         end if;
      elsif User_Data = Get_Object(Builder, "btnmapleft") then
         if CenterX - (MapWidth / 3) < 1 then
            CenterX := 1;
         else
            CenterX := CenterX - (MapWidth / 3);
         end if;
      elsif User_Data = Get_Object(Builder, "btnmapright") then
         if CenterX + (MapWidth / 3) > 1024 then
            CenterX := 1024;
         else
            CenterX := CenterX + (MapWidth / 3);
         end if;
      end if;
      Set_Text(Gtk_Text_Buffer(Get_Object(Builder, "txtmap")), "");
      DrawMap;
      Hide(Gtk_Widget(Get_Object(Builder, "movemapwindow")));
   end MoveMap;

   procedure BtnDockClicked(Object: access Gtkada_Builder_Record'Class) is
      Message: Unbounded_String := Null_Unbounded_String;
   begin
      if PlayerShip.Speed = DOCKED then
         Message := To_Unbounded_String(DockShip(False));
         if Length(Message) > 0 then
            ShowDialog
              (To_String(Message),
               Gtk_Window(Get_Object(Object, "skymapwindow")));
            return;
         end if;
      else
         Message := To_Unbounded_String(DockShip(True));
         if Length(Message) > 0 then
            ShowDialog
              (To_String(Message),
               Gtk_Window(Get_Object(Object, "skymapwindow")));
            return;
         end if;
      end if;
      UpdateHeader;
      UpdateMessages;
      UpdateMoveButtons;
   end BtnDockClicked;

   procedure ChangeSpeed(Object: access Gtkada_Builder_Record'Class) is
   begin
      PlayerShip.Speed :=
        ShipSpeed'Val
          (Get_Active(Gtk_Combo_Box(Get_Object(Object, "cmbspeed"))) + 1);
   end ChangeSpeed;

   procedure MoveShip(User_Data: access GObject_Record'Class) is
      Message: Unbounded_String;
      Result: Natural;
      StartsCombat: Boolean := False;
      NewX, NewY: Integer := 0;
   begin
      if User_Data = Get_Object(Builder, "btnup") then -- Move up
         Result := MoveShip(0, 0, -1, Message);
      elsif User_Data = Get_Object(Builder, "btnbottom") then -- Move down
         Result := MoveShip(0, 0, 1, Message);
      elsif User_Data = Get_Object(Builder, "btnright") then -- Move right
         Result := MoveShip(0, 1, 0, Message);
      elsif User_Data = Get_Object(Builder, "btnleft") then -- Move left
         Result := MoveShip(0, -1, 0, Message);
      elsif User_Data =
        Get_Object(Builder, "btnbottomleft") then -- Move down/left
         Result := MoveShip(0, -1, 1, Message);
      elsif User_Data =
        Get_Object(Builder, "btnbottomright") then -- Move down/right
         Result := MoveShip(0, 1, 1, Message);
      elsif User_Data = Get_Object(Builder, "btnupleft") then -- Move up/left
         Result := MoveShip(0, -1, -1, Message);
      elsif User_Data = Get_Object(Builder, "btnupright") then -- Move up/right
         Result := MoveShip(0, 1, -1, Message);
      elsif User_Data =
        Get_Object
          (Builder,
           "btnmovewait") then -- Move to destination or wait 1 game minute
         if PlayerShip.DestinationX = 0 and PlayerShip.DestinationY = 0 then
            Result := 1;
            UpdateGame(1);
         else
            if PlayerShip.DestinationX > PlayerShip.SkyX then
               NewX := 1;
            elsif PlayerShip.DestinationX < PlayerShip.SkyX then
               NewX := -1;
            end if;
            if PlayerShip.DestinationY > PlayerShip.SkyY then
               NewY := 1;
            elsif PlayerShip.DestinationY < PlayerShip.SkyY then
               NewY := -1;
            end if;
            Result := MoveShip(0, NewX, NewY, Message);
            if PlayerShip.DestinationX = PlayerShip.SkyX and
              PlayerShip.DestinationY = PlayerShip.SkyY then
               AddMessage
                 ("You reached your travel destination.",
                  OrderMessage);
               PlayerShip.DestinationX := 0;
               PlayerShip.DestinationY := 0;
               if GameSettings.AutoFinish then
                  Message := To_Unbounded_String(AutoFinishMissions);
               end if;
               Result := 4;
            end if;
         end if;
      elsif User_Data =
        Get_Object(Builder, "btnmoveto") then -- Move to destination
         loop
            NewX := 0;
            NewY := 0;
            if PlayerShip.DestinationX > PlayerShip.SkyX then
               NewX := 1;
            elsif PlayerShip.DestinationX < PlayerShip.SkyX then
               NewX := -1;
            end if;
            if PlayerShip.DestinationY > PlayerShip.SkyY then
               NewY := 1;
            elsif PlayerShip.DestinationY < PlayerShip.SkyY then
               NewY := -1;
            end if;
            Result := MoveShip(0, NewX, NewY, Message);
            exit when Result = 0;
            StartsCombat := CheckForEvent;
            if StartsCombat then
               Result := 4;
               exit;
            end if;
            if Result = 8 then
               WaitForRest;
               Result := 1;
               StartsCombat := CheckForEvent;
               if StartsCombat then
                  Result := 4;
                  exit;
               end if;
            end if;
            if GameSettings.AutoMoveStop /= NEVER and
              SkyMap(PlayerShip.SkyX, PlayerShip.SkyY).EventIndex > 0 then
               declare
                  EventIndex: constant Positive :=
                    SkyMap(PlayerShip.SkyX, PlayerShip.SkyY).EventIndex;
               begin
                  case GameSettings.AutoMoveStop is
                     when ANY =>
                        if Events_List(EventIndex).EType = EnemyShip or
                          Events_List(EventIndex).EType = Trader or
                          Events_List(EventIndex).EType = FriendlyShip or
                          Events_List(EventIndex).EType = EnemyPatrol then
                           Result := 0;
                           exit;
                        end if;
                     when FRIENDLY =>
                        if Events_List(EventIndex).EType = Trader or
                          Events_List(EventIndex).EType = FriendlyShip then
                           Result := 0;
                           exit;
                        end if;
                     when Config.ENEMY =>
                        if Events_List(EventIndex).EType = EnemyShip or
                          Events_List(EventIndex).EType = EnemyPatrol then
                           Result := 0;
                           exit;
                        end if;
                     when NEVER =>
                        null;
                  end case;
               end;
            end if;
            if PlayerShip.DestinationX = PlayerShip.SkyX and
              PlayerShip.DestinationY = PlayerShip.SkyY then
               AddMessage
                 ("You reached your travel destination.",
                  OrderMessage);
               PlayerShip.DestinationX := 0;
               PlayerShip.DestinationY := 0;
               if GameSettings.AutoFinish then
                  Message := To_Unbounded_String(AutoFinishMissions);
               end if;
               Result := 4;
               exit;
            end if;
            exit when Result = 6 or Result = 7;
         end loop;
      end if;
      case Result is
         when 1 => -- Ship moved, check for events
            StartsCombat := CheckForEvent;
            if not StartsCombat and GameSettings.AutoFinish then
               Message := To_Unbounded_String(AutoFinishMissions);
            end if;
         when 6 => -- Ship moved, but pilot needs rest, confirm
            if ShowConfirmDialog
                ("You don't have pilot on duty. Did you want to wait until your pilot rest?",
                 Gtk_Window(Get_Object(Builder, "skymapwindow"))) then
               WaitForRest;
               StartsCombat := CheckForEvent;
               if not StartsCombat and GameSettings.AutoFinish then
                  Message := To_Unbounded_String(AutoFinishMissions);
               end if;
            end if;
         when 7 => -- Ship moved, but engineer needs rest, confirm
            if ShowConfirmDialog
                ("You don't have engineer on duty. Did you want to wait until your engineer rest?",
                 Gtk_Window(Get_Object(Builder, "skymapwindow"))) then
               WaitForRest;
               StartsCombat := CheckForEvent;
               if not StartsCombat and GameSettings.AutoFinish then
                  Message := To_Unbounded_String(AutoFinishMissions);
               end if;
            end if;
         when 8 => -- Ship moved, but crew needs rest, autorest
            StartsCombat := CheckForEvent;
            if not StartsCombat then
               WaitForRest;
               StartsCombat := CheckForEvent;
            end if;
            if not StartsCombat and GameSettings.AutoFinish then
               Message := To_Unbounded_String(AutoFinishMissions);
            end if;
         when others =>
            null;
      end case;
      if Message /= Null_Unbounded_String then
         ShowDialog
           (To_String(Message),
            Gtk_Window(Get_Object(Builder, "skymapwindow")));
      end if;
      if Result > 0 then
         CenterX := PlayerShip.SkyX;
         CenterY := PlayerShip.SkyY;
      end if;
      if StartsCombat then
         ShowCombatUI;
      end if;
      if Result > 0 then
         UpdateHeader;
         UpdateMessages;
         UpdateMoveButtons;
         DrawMap;
      end if;
   end MoveShip;

   procedure ShowOrders(Object: access Gtkada_Builder_Record'Class) is
      HaveTrader: Boolean := False;
      BaseIndex: constant Natural :=
        SkyMap(PlayerShip.SkyX, PlayerShip.SkyY).BaseIndex;
      MissionsLimit: Integer;
      Event: Events_Types := None;
      ItemIndex: Natural;
   begin
      Foreach
        (Gtk_Container(Get_Object(Object, "btnboxorders")),
         HideButtons'Access);
      if FindMember(Talk) > 0 then
         HaveTrader := True;
      end if;
      if PlayerShip.Speed = DOCKED then
         if HaveTrader and SkyBases(BaseIndex).Owner /= Abandoned then
            Set_No_Show_All(Gtk_Widget(Get_Object(Object, "btntrade")), False);
            Set_No_Show_All
              (Gtk_Widget(Get_Object(Object, "btnschool")),
               False);
            if SkyBases(BaseIndex).Recruits.Length > 0 then
               Set_No_Show_All
                 (Gtk_Widget(Get_Object(Object, "btnrecruit")),
                  False);
            end if;
            if DaysDifference(SkyBases(BaseIndex).AskedForEvents) > 6 then
               Set_No_Show_All
                 (Gtk_Widget(Get_Object(Object, "btnaskevents")),
                  False);
            end if;
            if not SkyBases(BaseIndex).AskedForBases then
               Set_No_Show_All
                 (Gtk_Widget(Get_Object(Object, "btnaskbases")),
                  False);
            end if;
            for Member of PlayerShip.Crew loop
               if Member.Health < 100 then
                  Set_No_Show_All
                    (Gtk_Widget(Get_Object(Object, "btnheal")),
                     False);
                  exit;
               end if;
            end loop;
            for Module of PlayerShip.Modules loop
               if Module.Durability < Module.MaxDurability then
                  Set_No_Show_All
                    (Gtk_Widget(Get_Object(Object, "btnrepair")),
                     False);
                  exit;
               end if;
            end loop;
            if SkyBases(BaseIndex).BaseType = Shipyard then
               Set_No_Show_All
                 (Gtk_Widget(Get_Object(Object, "btnshipyard")),
                  False);
            end if;
            for I in Recipes_List.First_Index .. Recipes_List.Last_Index loop
               if Known_Recipes.Find_Index(Item => I) =
                 Positive_Container.No_Index and
                 Recipes_List(I).BaseType =
                   Bases_Types'Pos(SkyBases(BaseIndex).BaseType) + 1 then
                  Set_No_Show_All
                    (Gtk_Widget(Get_Object(Object, "btnrecipes")),
                     False);
                  exit;
               end if;
            end loop;
            if SkyBases(BaseIndex).Missions.Length > 0 then
               case SkyBases(BaseIndex).Reputation(1) is
                  when 0 .. 25 =>
                     MissionsLimit := 1;
                  when 26 .. 50 =>
                     MissionsLimit := 3;
                  when 51 .. 75 =>
                     MissionsLimit := 5;
                  when 76 .. 100 =>
                     MissionsLimit := 10;
                  when others =>
                     MissionsLimit := 0;
               end case;
               for Mission of PlayerShip.Missions loop
                  if (Mission.Finished and Mission.StartBase = BaseIndex) or
                    (Mission.TargetX = PlayerShip.SkyX and
                     Mission.TargetY = PlayerShip.SkyY) then
                     case Mission.MType is
                        when Deliver =>
                           Set_Label
                             (Gtk_Button
                                (Get_Object(Object, "btnfinishmission")),
                              "_Complete delivery of " &
                              To_String(Items_List(Mission.Target).Name));
                        when Destroy =>
                           if Mission.Finished then
                              Set_Label
                                (Gtk_Button
                                   (Get_Object(Object, "btnfinishmission")),
                                 "_Complete destroy " &
                                 To_String
                                   (ProtoShips_List(Mission.Target).Name));
                           end if;
                        when Patrol =>
                           if Mission.Finished then
                              Set_Label
                                (Gtk_Button
                                   (Get_Object(Object, "btnfinishmission")),
                                 "_Complete Patrol area mission");
                           end if;
                        when Explore =>
                           if Mission.Finished then
                              Set_Label
                                (Gtk_Button
                                   (Get_Object(Object, "btnfinishmission")),
                                 "_Complete Explore area mission");
                           end if;
                        when Passenger =>
                           if Mission.Finished then
                              Set_Label
                                (Gtk_Button
                                   (Get_Object(Object, "btnfinishmission")),
                                 "_Complete Transport passenger mission");
                           end if;
                     end case;
                     Set_No_Show_All
                       (Gtk_Widget(Get_Object(Object, "btnfinishmission")),
                        False);
                  end if;
                  if Mission.StartBase = BaseIndex then
                     MissionsLimit := MissionsLimit - 1;
                  end if;
               end loop;
               if MissionsLimit > 0 then
                  Set_No_Show_All
                    (Gtk_Widget(Get_Object(Object, "btnmissions")),
                     False);
               end if;
            end if;
            if PlayerShip.HomeBase /= BaseIndex then
               Set_No_Show_All
                 (Gtk_Widget(Get_Object(Object, "btnsethome")),
                  False);
            end if;
         end if;
         if SkyBases(BaseIndex).Owner = Abandoned then
            Set_No_Show_All(Gtk_Widget(Get_Object(Object, "btnloot")), False);
         end if;
      else
         if SkyMap(PlayerShip.SkyX, PlayerShip.SkyY).EventIndex > 0 then
            Event :=
              Events_List(SkyMap(PlayerShip.SkyX, PlayerShip.SkyY).EventIndex)
                .EType;
         end if;
         case Event is
            when EnemyShip | EnemyPatrol =>
               Set_No_Show_All
                 (Gtk_Widget(Get_Object(Object, "btnattack")),
                  False);
               Set_Label
                 (Gtk_Button(Get_Object(Object, "btnattack")),
                  "Attack");
            when FullDocks =>
               Set_No_Show_All
                 (Gtk_Widget(Get_Object(Object, "btnattack")),
                  False);
               Set_Label(Gtk_Button(Get_Object(Object, "btnattack")), "_Wait");
            when AttackOnBase =>
               Set_No_Show_All
                 (Gtk_Widget(Get_Object(Object, "btnattack")),
                  False);
               Set_Label
                 (Gtk_Button(Get_Object(Object, "btnattack")),
                  "Defend");
            when Disease =>
               if HaveTrader then
                  ItemIndex :=
                    FindItem
                      (Inventory => PlayerShip.Cargo,
                       ItemType => HealingTools);
                  if ItemIndex > 0 then
                     Set_No_Show_All
                       (Gtk_Widget(Get_Object(Object, "btnfreemedicines")),
                        False);
                     Set_No_Show_All
                       (Gtk_Widget(Get_Object(Object, "btnpricedmedicines")),
                        False);
                  end if;
               end if;
            when None | DoublePrice | BaseRecovery =>
               if BaseIndex > 0 then
                  for Mission of PlayerShip.Missions loop
                     if HaveTrader then
                        case Mission.MType is
                           when Deliver =>
                              Set_Label
                                (Gtk_Button
                                   (Get_Object(Object, "btnfinishmission")),
                                 "_Complete delivery of " &
                                 To_String(Items_List(Mission.Target).Name));
                           when Destroy =>
                              if Mission.Finished then
                                 Set_Label
                                   (Gtk_Button
                                      (Get_Object(Object, "btnfinishmission")),
                                    "_Complete destroy " &
                                    To_String
                                      (ProtoShips_List(Mission.Target).Name));
                              end if;
                           when Patrol =>
                              if Mission.Finished then
                                 Set_Label
                                   (Gtk_Button
                                      (Get_Object(Object, "btnfinishmission")),
                                    "_Complete Patrol area mission");
                              end if;
                           when Explore =>
                              if Mission.Finished then
                                 Set_Label
                                   (Gtk_Button
                                      (Get_Object(Object, "btnfinishmission")),
                                    "_Complete Explore area mission");
                              end if;
                           when Passenger =>
                              if Mission.Finished then
                                 Set_Label
                                   (Gtk_Button
                                      (Get_Object(Object, "btnfinishmission")),
                                    "_Complete Transport passenger mission");
                              end if;
                        end case;
                        Set_No_Show_All
                          (Gtk_Widget(Get_Object(Object, "btnfinishmission")),
                           False);
                     end if;
                  end loop;
               else
                  for Mission of PlayerShip.Missions loop
                     if Mission.TargetX = PlayerShip.SkyX and
                       Mission.TargetY = PlayerShip.SkyY and
                       not Mission.Finished then
                        case Mission.MType is
                           when Deliver | Passenger =>
                              null;
                           when Destroy =>
                              Set_Label
                                (Gtk_Button
                                   (Get_Object(Object, "btncurrentmission")),
                                 "_Search for " &
                                 To_String
                                   (ProtoShips_List(Mission.Target).Name));
                           when Patrol =>
                              Set_Label
                                (Gtk_Button
                                   (Get_Object(Object, "btncurrentmission")),
                                 "_Patrol area");
                           when Explore =>
                              Set_Label
                                (Gtk_Button
                                   (Get_Object(Object, "btncurrentmission")),
                                 "_Explore area");
                        end case;
                        Set_No_Show_All
                          (Gtk_Widget(Get_Object(Object, "btncurrentmission")),
                           False);
                     end if;
                  end loop;
               end if;
            when Trader =>
               if HaveTrader then
                  Set_No_Show_All
                    (Gtk_Widget(Get_Object(Object, "btntrade")),
                     False);
                  Set_No_Show_All
                    (Gtk_Widget(Get_Object(Object, "btnaskevents")),
                     False);
                  Set_No_Show_All
                    (Gtk_Widget(Get_Object(Object, "btnaskbases")),
                     False);
               end if;
               Set_No_Show_All
                 (Gtk_Widget(Get_Object(Object, "btnattack")),
                  False);
               Set_Label
                 (Gtk_Button(Get_Object(Object, "btnattack")),
                  "Attack");
            when FriendlyShip =>
               if HaveTrader then
                  if Index
                      (ProtoShips_List
                         (Events_List
                            (SkyMap(PlayerShip.SkyX, PlayerShip.SkyY)
                               .EventIndex)
                            .Data)
                         .Name,
                       To_String(TradersName)) >
                    0 then
                     Set_No_Show_All
                       (Gtk_Widget(Get_Object(Object, "btntrade")),
                        False);
                     Set_No_Show_All
                       (Gtk_Widget(Get_Object(Object, "btnaskbases")),
                        False);
                  end if;
                  Set_No_Show_All
                    (Gtk_Widget(Get_Object(Object, "btnaskevents")),
                     False);
               end if;
               Set_No_Show_All
                 (Gtk_Widget(Get_Object(Object, "btnattack")),
                  False);
               Set_Label
                 (Gtk_Button(Get_Object(Object, "btnattack")),
                  "Attack");
         end case;
      end if;
      ButtonsVisible := False;
      Foreach
        (Gtk_Container(Get_Object(Object, "btnboxorders")),
         CheckButtons'Access);
      if ButtonsVisible then
         Show_All(Gtk_Widget(Get_Object(Object, "orderswindow")));
      else
         ShowDialog
           ("Here are no available ship orders at this moment.",
            Gtk_Window(Get_Object(Object, "skymapwindow")));
      end if;
   end ShowOrders;

   procedure WaitOrder(User_Data: access GObject_Record'Class) is
      TimeNeeded: Natural := 0;
   begin
      Hide(Gtk_Widget(Get_Object(Builder, "waitwindow")));
      if User_Data = Get_Object(Builder, "btn1min") then
         UpdateGame(1);
      elsif User_Data = Get_Object(Builder, "btnwait5min") then
         UpdateGame(5);
      elsif User_Data = Get_Object(Builder, "btnwait10min") then
         UpdateGame(10);
      elsif User_Data = Get_Object(Builder, "btnwait15min") then
         UpdateGame(15);
      elsif User_Data = Get_Object(Builder, "btnwait30min") then
         UpdateGame(30);
      elsif User_Data = Get_Object(Builder, "btnwait1hour") then
         UpdateGame(60);
      elsif User_Data = Get_Object(Builder, "btnwaitrest") then
         WaitForRest;
      elsif User_Data = Get_Object(Builder, "btnwaitheal") then
         for I in PlayerShip.Crew.Iterate loop
            if PlayerShip.Crew(I).Health < 100 and
              PlayerShip.Crew(I).Health > 0 and
              PlayerShip.Crew(I).Order = Rest then
               for Module of PlayerShip.Modules loop
                  if Modules_List(Module.ProtoIndex).MType = CABIN and
                    Module.Owner = Crew_Container.To_Index(I) then
                     if TimeNeeded <
                       (100 - PlayerShip.Crew(I).Health) * 15 then
                        TimeNeeded := (100 - PlayerShip.Crew(I).Health) * 15;
                     end if;
                     exit;
                  end if;
               end loop;
            end if;
         end loop;
         if TimeNeeded > 0 then
            UpdateGame(TimeNeeded);
         else
            return;
         end if;
      elsif User_Data = Get_Object(Builder, "waitxadj") then
         UpdateGame(Positive(Get_Value(Gtk_Adjustment(User_Data))));
      end if;
      UpdateHeader;
      UpdateMessages;
      UpdateMoveButtons;
      DrawMap;
   end WaitOrder;

   procedure AttackOrder(Object: access Gtkada_Builder_Record'Class) is
      BtnAttack: constant Gtk_Button :=
        Gtk_Button(Get_Object(Object, "btnattack"));
      Label: constant String := Get_Label(BtnAttack);
   begin
      Hide(Gtk_Widget(Get_Object(Builder, "orderswindow")));
      if Label = "Wait" then
         Show_All(Gtk_Widget(Get_Object(Builder, "waitwindow")));
      else
         ShowCombatUI;
      end if;
   end AttackOrder;

   procedure ShowHelp(Object: access Gtkada_Builder_Record'Class) is
   begin
      if Get_Visible_Child_Name(Gtk_Stack(Get_Object(Object, "gamestack"))) =
        "combat" then
         ShowHelpUI(4);
      elsif Get_Visible_Child_Name
          (Gtk_Stack(Get_Object(Object, "gamestack"))) =
        "crafts" then
         ShowHelpUI(5);
      elsif Get_Visible_Child_Name
          (Gtk_Stack(Get_Object(Object, "gamestack"))) =
        "crew" then
         ShowHelpUI(7);
      elsif Get_Visible_Child_Name
          (Gtk_Stack(Get_Object(Object, "gamestack"))) =
        "ship" then
         ShowHelpUI(6);
      elsif Get_Visible_Child_Name
          (Gtk_Stack(Get_Object(Object, "gamestack"))) =
        "trade" then
         ShowHelpUI(3);
      elsif Get_Visible_Child_Name
          (Gtk_Stack(Get_Object(Object, "gamestack"))) =
        "skymap" then
         ShowHelpUI(1);
      end if;
   end ShowHelp;

   procedure ShowInfo(User_Data: access GObject_Record'Class) is
   begin
      if User_Data = Get_Object(Builder, "menumissions") then
         if PlayerShip.Missions.Length = 0 then
            ShowDialog
              ("You didn't accepted any mission yet.",
               Gtk_Window(Get_Object(Builder, "skymapwindow")));
            return;
         end if;
      elsif User_Data = Get_Object(Builder, "menuevents") then
         if Events_List.Length = 0 then
            ShowDialog
              ("You dont know any event yet.",
               Gtk_Window(Get_Object(Builder, "skymapwindow")));
            return;
         end if;
      end if;
      Hide(Gtk_Widget(Get_Object(Builder, "btnmenu")));
      Show_All(Gtk_Widget(Get_Object(Builder, "btnclose")));
      if User_Data = Get_Object(Builder, "menumessages") then
         ShowMessagesUI(SkyMap_View);
      elsif User_Data = Get_Object(Builder, "menucargo") then
         ShowCargoUI(SkyMap_View);
      elsif User_Data = Get_Object(Builder, "menuship") then
         ShowShipUI(SkyMap_View);
      elsif User_Data = Get_Object(Builder, "menucrew") then
         ShowCrewUI(SkyMap_View);
      elsif User_Data = Get_Object(Builder, "menustats") then
         ShowStatsUI(SkyMap_View);
      elsif User_Data = Get_Object(Builder, "menumissions") then
         ShowAcceptedMissions;
      elsif User_Data = Get_Object(Builder, "btntrade") then
         Hide(Gtk_Widget(Get_Object(Builder, "orderswindow")));
         if SkyMap(PlayerShip.SkyX, PlayerShip.SkyY).BaseIndex = 0 then
            GenerateTraderCargo
              (Events_List(SkyMap(PlayerShip.SkyX, PlayerShip.SkyY).EventIndex)
                 .Data);
         end if;
         ShowTradeUI;
      elsif User_Data = Get_Object(Builder, "btnrecruit") then
         Hide(Gtk_Widget(Get_Object(Builder, "orderswindow")));
         ShowRecruitUI;
      elsif User_Data = Get_Object(Builder, "btnrecipes") then
         Hide(Gtk_Widget(Get_Object(Builder, "orderswindow")));
         ShowBuyRecipesUI;
      elsif User_Data = Get_Object(Builder, "btnrepair") then
         Hide(Gtk_Widget(Get_Object(Builder, "orderswindow")));
         ShowRepairUI;
      elsif User_Data = Get_Object(Builder, "btnheal") then
         Hide(Gtk_Widget(Get_Object(Builder, "orderswindow")));
         ShowHealUI;
      elsif User_Data = Get_Object(Builder, "btnschool") then
         Hide(Gtk_Widget(Get_Object(Builder, "orderswindow")));
         ShowSchoolUI;
      elsif User_Data = Get_Object(Builder, "btnshipyard") then
         Hide(Gtk_Widget(Get_Object(Builder, "orderswindow")));
         ShowShipyardUI;
      elsif User_Data = Get_Object(Builder, "btnloot") then
         Hide(Gtk_Widget(Get_Object(Builder, "orderswindow")));
         ShowLootUI;
      elsif User_Data = Get_Object(Builder, "menucrafting") then
         ShowCraftsUI;
      elsif User_Data = Get_Object(Builder, "menubaseslist") then
         ShowBasesListUI;
      elsif User_Data = Get_Object(Builder, "menuevents") then
         ShowEventsUI;
      elsif User_Data = Get_Object(Builder, "menuoptions") then
         ShowGameOptions;
      end if;
   end ShowInfo;

   procedure ResignFromGame(Object: access Gtkada_Builder_Record'Class) is
   begin
      if ShowConfirmDialog
          ("Are you sure want to resign from game?",
           Gtk_Window(Get_Object(Object, "skymapwindow"))) then
         Death(1, To_Unbounded_String("resignation"), PlayerShip);
         DeathConfirm;
      end if;
   end ResignFromGame;

   procedure ShowMissions(Object: access Gtkada_Builder_Record'Class) is
   begin
      Hide(Gtk_Widget(Get_Object(Object, "orderswindow")));
      Hide(Gtk_Widget(Get_Object(Builder, "btnmenu")));
      Show_All(Gtk_Widget(Get_Object(Builder, "btnclose")));
      ShowMissionsUI;
   end ShowMissions;

   procedure StartMission(Object: access Gtkada_Builder_Record'Class) is
      StartsCombat: Boolean := False;
   begin
      Hide(Gtk_Widget(Get_Object(Object, "orderswindow")));
      for Mission of PlayerShip.Missions loop
         if Mission.TargetX = PlayerShip.SkyX and
           Mission.TargetY = PlayerShip.SkyY and
           not Mission.Finished then
            case Mission.MType is
               when Deliver | Passenger =>
                  null;
               when Destroy =>
                  UpdateGame(GetRandom(15, 45));
                  StartsCombat := CheckForEvent;
                  if not StartsCombat then
                     StartsCombat :=
                       StartCombat
                         (PlayerShip.Missions
                            (SkyMap(PlayerShip.SkyX, PlayerShip.SkyY)
                               .MissionIndex)
                            .Target,
                          False);
                  end if;
               when Patrol =>
                  UpdateGame(GetRandom(45, 75));
                  StartsCombat := CheckForEvent;
                  if not StartsCombat then
                     UpdateMission
                       (SkyMap(PlayerShip.SkyX, PlayerShip.SkyY).MissionIndex);
                  end if;
               when Explore =>
                  UpdateGame(GetRandom(30, 60));
                  StartsCombat := CheckForEvent;
                  if not StartsCombat then
                     UpdateMission
                       (SkyMap(PlayerShip.SkyX, PlayerShip.SkyY).MissionIndex);
                  end if;
            end case;
            exit;
         end if;
      end loop;
      if StartsCombat then
         ShowCombatUI;
         return;
      end if;
      UpdateHeader;
      UpdateMessages;
      UpdateMoveButtons;
      DrawMap;
   end StartMission;

   procedure CompleteMission(Object: access Gtkada_Builder_Record'Class) is
   begin
      Hide(Gtk_Widget(Get_Object(Object, "orderswindow")));
      FinishMission(SkyMap(PlayerShip.SkyX, PlayerShip.SkyY).MissionIndex);
      UpdateHeader;
      UpdateMessages;
      UpdateMoveButtons;
      DrawMap;
   end CompleteMission;

   procedure ExecuteOrder(User_Data: access GObject_Record'Class) is
      TraderIndex: constant Natural := FindMember(Talk);
      Price: Positive := 1000;
      MoneyIndex2: constant Natural :=
        FindItem(PlayerShip.Cargo, FindProtoItem(MoneyIndex));
   begin
      Hide(Gtk_Widget(Get_Object(Builder, "orderswindow")));
      if User_Data = Get_Object(Builder, "btnaskevents") then
         AskForEvents;
      elsif User_Data = Get_Object(Builder, "btnaskbases") then
         AskForBases;
      else
         CountPrice(Price, TraderIndex);
         if ShowConfirmDialog
             ("Are you sure want to change your home base (it cost" &
              Positive'Image(Price) &
              " " &
              To_String(MoneyName) &
              ")?",
              Gtk_Window(Get_Object(Builder, "skymapwindow"))) then
            if MoneyIndex2 = 0 then
               ShowDialog
                 ("You don't have any " &
                  To_String(MoneyName) &
                  " for change ship home base.",
                  Gtk_Window(Get_Object(Builder, "skymapwindow")));
               return;
            end if;
            CountPrice(Price, TraderIndex);
            if PlayerShip.Cargo(MoneyIndex2).Amount < Price then
               ShowDialog
                 ("You don't have enough " &
                  To_String(MoneyName) &
                  " for change ship home base.",
                  Gtk_Window(Get_Object(Builder, "skymapwindow")));
               return;
            end if;
            PlayerShip.HomeBase :=
              SkyMap(PlayerShip.SkyX, PlayerShip.SkyY).BaseIndex;
            UpdateCargo
              (Ship => PlayerShip,
               CargoIndex => MoneyIndex2,
               Amount => (0 - Price));
            AddMessage
              ("You changed your ship home base to: " &
               To_String(SkyBases(PlayerShip.HomeBase).Name),
               OtherMessage);
            GainExp(1, TalkingSkill, TraderIndex);
            UpdateGame(10);
         end if;
      end if;
      UpdateHeader;
      UpdateMessages;
      UpdateMoveButtons;
      DrawMap;
   end ExecuteOrder;

   procedure DeliverMedicines(User_Data: access GObject_Record'Class) is
      EventIndex, ItemIndex: Natural := 0;
      NewTime: Integer;
   begin
      EventIndex := SkyMap(PlayerShip.SkyX, PlayerShip.SkyY).EventIndex;
      ItemIndex :=
        FindItem(Inventory => PlayerShip.Cargo, ItemType => HealingTools);
      NewTime :=
        Events_List(EventIndex).Time - PlayerShip.Cargo(ItemIndex).Amount;
      if NewTime < 1 then
         DeleteEvent(EventIndex);
      else
         Events_List(EventIndex).Time := NewTime;
      end if;
      if User_Data = Get_Object(Builder, "btnfreemedicines") then
         GainRep
           (SkyMap(PlayerShip.SkyX, PlayerShip.SkyY).BaseIndex,
            (PlayerShip.Cargo(ItemIndex).Amount / 10));
         UpdateCargo
           (PlayerShip,
            PlayerShip.Cargo.Element(ItemIndex).ProtoIndex,
            (0 - PlayerShip.Cargo.Element(ItemIndex).Amount));
         AddMessage
           ("You gave " &
            To_String
              (Items_List(PlayerShip.Cargo(ItemIndex).ProtoIndex).Name) &
            " for free to base.",
            TradeMessage);
      else
         SellItems
           (ItemIndex,
            Integer'Image(PlayerShip.Cargo.Element(ItemIndex).Amount));
         GainRep
           (SkyMap(PlayerShip.SkyX, PlayerShip.SkyY).BaseIndex,
            ((PlayerShip.Cargo(ItemIndex).Amount / 20) * (-1)));
      end if;
   end DeliverMedicines;

   procedure ShowWaitOrders(Object: access Gtkada_Builder_Record'Class) is
      NeedHealing, NeedRest: Boolean := False;
   begin
      for I in PlayerShip.Crew.First_Index .. PlayerShip.Crew.Last_Index loop
         if PlayerShip.Crew(I).Tired > 0 and
           PlayerShip.Crew(I).Order = Rest then
            NeedRest := True;
         end if;
         if PlayerShip.Crew(I).Health < 100 and
           PlayerShip.Crew(I).Health > 0 and
           PlayerShip.Crew(I).Order = Rest then
            for Module of PlayerShip.Modules loop
               if Modules_List(Module.ProtoIndex).MType = CABIN and
                 Module.Owner = I then
                  NeedHealing := True;
                  exit;
               end if;
            end loop;
         end if;
      end loop;
      Set_Visible(Gtk_Widget(Get_Object(Object, "btnwaitheal")), NeedHealing);
      Set_Visible(Gtk_Widget(Get_Object(Object, "btnwaitrest")), NeedRest);
      Show_All(Gtk_Widget(Get_Object(Object, "waitwindow")));
   end ShowWaitOrders;

   function UpdateTooltip
     (Object: access Gtkada_Builder_Record'Class) return Boolean is
      MapInfoText: Unbounded_String;
   begin
      GetCurrentCellCoords;
      Append
        (MapInfoText,
         "X:" & Positive'Image(MapX) & " Y:" & Positive'Image(MapY));
      BuildMapInfo(MapInfoText);
      Set_Tooltip_Text
        (Gtk_Widget(Get_Object(Object, "mapview")),
         To_String(MapInfoText));
      return False;
   end UpdateTooltip;

end Maps.UI.Handlers;
