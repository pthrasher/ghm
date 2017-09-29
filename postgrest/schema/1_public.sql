set search_path to public;

/*
 * customers
 */
create view customers as select
      customer_id

    , title
    , title_letter

    , given
    , second
    , family

    , company
    , company_address

    , street
    , street_number
    , city
    , postal_code
    , country
    , country_code

    , phone
    , phone2
    , mobile
    , fax
    , fax2
    , mail
    , mail2
    , web

    , keyword
    , note
  from internal.customers;

/*
 * insert to customers
 *
 * - customer_id can't be specified
 * - coalescing
 */
create rule customers_insert as on insert to customers do instead
  insert into internal.customers
    ( title
    , title_letter

    , given
    , second
    , family

    , company
    , company_address

    , street
    , street_number
    , city
    , postal_code
    , country
    , country_code

    , phone
    , phone2
    , mobile
    , fax
    , fax2
    , mail
    , mail2
    , web

    , keyword
    , note
  ) values
    ( trim(coalesce(new.title           ,''))
    , trim(coalesce(new.title_letter    ,''))

    , trim(coalesce(new.given           ,''))
    , trim(coalesce(new.second          ,''))
    , trim(coalesce(new.family          ,''))

    , trim(coalesce(new.company         ,''))
    , trim(coalesce(new.company_address ,''))

    , trim(coalesce(new.street          ,''))
    , trim(coalesce(new.street_number   ,''))
    , trim(coalesce(new.city            ,''))
    , trim(coalesce(new.postal_code     ,''))
    , trim(coalesce(new.country         ,''))
    , trim(coalesce(new.country_code    ,''))

    , trim(coalesce(new.phone           ,''))
    , trim(coalesce(new.phone2          ,''))
    , trim(coalesce(new.mobile          ,''))
    , trim(coalesce(new.fax             ,''))
    , trim(coalesce(new.fax2            ,''))
    , trim(coalesce(new.mail            ,''))
    , trim(coalesce(new.mail2           ,''))
    , trim(coalesce(new.web             ,''))

    , trim(coalesce(new.keyword         ,''))
    , trim(coalesce(new.note            ,''))
    )
  returning customers.*
  ;

/*
 * update customers
 *
 * - customer_id can't be changed
 */
create rule customers_update as on update to customers do instead
  update internal.customers set
    title           = trim(coalesce(new.title           , old.title          )),
    title_letter    = trim(coalesce(new.title_letter    , old.title_letter   )),

    given           = trim(coalesce(new.given           , old.given          )),
    second          = trim(coalesce(new.second          , old.second         )),
    family          = trim(coalesce(new.family          , old.family         )),

    company         = trim(coalesce(new.company         , old.company        )),
    company_address = trim(coalesce(new.company_address , old.company_address)),

    street          = trim(coalesce(new.street          , old.street         )),
    street_number   = trim(coalesce(new.street_number   , old.street_number  )),
    city            = trim(coalesce(new.city            , old.city           )),
    postal_code     = trim(coalesce(new.postal_code     , old.postal_code    )),
    country         = trim(coalesce(new.country         , old.country        )),
    country_code    = trim(coalesce(new.country_code    , old.country_code   )),

    phone           = trim(coalesce(new.phone           , old.phone          )),
    phone2          = trim(coalesce(new.phone2          , old.phone2         )),
    mobile          = trim(coalesce(new.mobile          , old.mobile         )),
    fax             = trim(coalesce(new.fax             , old.fax            )),
    fax2            = trim(coalesce(new.fax2            , old.fax2           )),
    mail            = trim(coalesce(new.mail            , old.mail           )),
    mail2           = trim(coalesce(new.mail2           , old.mail2          )),
    web             = trim(coalesce(new.web             , old.web            )),

    keyword         = trim(coalesce(new.keyword         , old.keyword        )),
    note            = trim(coalesce(new.note            , old.note           ))
  where customer_id = new.customer_id
  returning customers.*;

/*
 * bookings
 */
create view bookings as select
    booking_id,
    customer_id,

    state,
    deposit_asked,
    deposit_got,
    no_tax,
    note
  from internal.bookings;

/*
 * insert booking
 *
 * - booking_id can't be set
 */
create rule bookings_insert as on insert to bookings do instead
  insert into internal.bookings
    ( booking_id

    , state
    , deposit_asked
    , deposit_got
    , no_tax
    , note
    ) values
    ( new.booking_id

    , new.state
    , new.deposit_asked
    , new.deposit_got
    , coalesce(new.no_tax, false)
    , trim(coalesce(new.note, ''))
    )
  returning bookings.*
  ;

create view booked_rooms as select
    booked_room_id,
    booking_id,
    room_id,

    beds,
    price_per_bed,
    factor,

    description,

    breakfast,

    from_date,
    to_date
  from internal.booked_rooms;

/*
 * insert booked_room
 *
 * - id can't be set
 */
create rule booked_rooms_insert as on insert to booked_rooms do instead
  insert into internal.booked_rooms
    ( booking_id
    , room_id

    , beds
    , price_per_bed
    , factor

    , description
    , breakfast

    , from_date
    , to_date
    ) values
    ( new.booking_id
    , new.room_id

    , new.beds
    , new.price_per_bed
    , new.factor

    , trim(coalesce(new.description,''))
    , new.breakfast

    , new.from_date
    , new.to_date
    )
  returning booked_rooms.*
  ;

/*
 * booked_individuals
 */
create view booked_individuals as select
    booked_individual_id,
    booking_id,

    given,
    second,
    family,
    date_of_birth
  from internal.booked_individuals;

/*
 * insert
 *
 * - id can't be set
 */
 /* todo */

/*
 * static configuration tables
 *
 * - rooms
 * - booking_states
 */
create view rooms          as select * from internal.rooms;
create view booking_states as select * from internal.booking_states;
