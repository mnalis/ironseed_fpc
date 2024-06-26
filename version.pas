unit version;
(********************************************************************
    This file is part of Ironseed.

    Ironseed is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Ironseed is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Ironseed.  If not, see <https://www.gnu.org/licenses/>.
********************************************************************)

{*********************************************
   Version string for IronSeed

   Copyright:
    1994 Channel 7, Destiny: Virtual
    2013 y-salnikov
    2020,2024 Matija Nalis <mnalis-git@voyager.hr>
**********************************************}

interface

var
   versionstring :string[20];

implementation

begin
   versionstring :=
   {12345678901234567890}
   'v1.30.0001 fpc 0.4.0';
end.
