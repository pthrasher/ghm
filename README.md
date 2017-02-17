ghm - Guesthouse Manager
========================

Booking management built in elm and postgres(t).

Todo
----

  * Trim data on insert/update
  * Prevent inserts with higher id's than serial currently is
  * Migrate missing fields from combit to ghm
      - Kundennr, Kategorie: Bemerkung/Sideinfo -> Notiz
      - Plzp, Postfach: Kommentar/2te Adresse -> Notiz
      - Geburtsdaten
  * Combit import seems to use same date on from/to
  * Delete all phone/fax numbers ending in /

Next steps
----------

  * select booking from list
  * show complete booking information
  * editing
  * Insert new bookings for existing customers
  * saving

