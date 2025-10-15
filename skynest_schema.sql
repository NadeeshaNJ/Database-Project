--
-- PostgreSQL database dump
--

\restrict DP1rxBdRWDSruhnnJ251IdPsyVMNYcKxPlWT6wVFC4BQDOMwAAnff9cOzVJUEzG

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.6

-- Started on 2025-10-07 20:48:42

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 5425 (class 1262 OID 16387)
-- Name: skynest; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE skynest WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'English_United States.1252';


ALTER DATABASE skynest OWNER TO postgres;

\unrestrict DP1rxBdRWDSruhnnJ251IdPsyVMNYcKxPlWT6wVFC4BQDOMwAAnff9cOzVJUEzG
\connect skynest
\restrict DP1rxBdRWDSruhnnJ251IdPsyVMNYcKxPlWT6wVFC4BQDOMwAAnff9cOzVJUEzG

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 2 (class 3079 OID 16653)
-- Name: btree_gist; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS btree_gist WITH SCHEMA public;


--
-- TOC entry 5426 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION btree_gist; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION btree_gist IS 'support for indexing common datatypes in GiST';


--
-- TOC entry 1165 (class 1247 OID 17807)
-- Name: adjustment_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.adjustment_type AS ENUM (
    'refund',
    'chargeback',
    'manual_adjustment'
);


ALTER TYPE public.adjustment_type OWNER TO postgres;

--
-- TOC entry 1093 (class 1247 OID 16430)
-- Name: booking_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.booking_status AS ENUM (
    'Booked',
    'Checked-In',
    'Checked-Out',
    'Cancelled'
);


ALTER TYPE public.booking_status OWNER TO postgres;

--
-- TOC entry 1087 (class 1247 OID 16412)
-- Name: payment_method; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.payment_method AS ENUM (
    'Cash',
    'Card',
    'Online',
    'BankTransfer'
);


ALTER TYPE public.payment_method OWNER TO postgres;

--
-- TOC entry 1096 (class 1247 OID 16440)
-- Name: prebooking_method; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.prebooking_method AS ENUM (
    'Online',
    'Phone',
    'Walk-in'
);


ALTER TYPE public.prebooking_method OWNER TO postgres;

--
-- TOC entry 1090 (class 1247 OID 16422)
-- Name: room_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.room_status AS ENUM (
    'Available',
    'Occupied',
    'Maintenance'
);


ALTER TYPE public.room_status OWNER TO postgres;

--
-- TOC entry 1084 (class 1247 OID 16400)
-- Name: user_role; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.user_role AS ENUM (
    'Admin',
    'Manager',
    'Receptionist',
    'Accountant',
    'Customer'
);


ALTER TYPE public.user_role OWNER TO postgres;

--
-- TOC entry 359 (class 1255 OID 17775)
-- Name: fn_balance_due(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_balance_due(p bigint) RETURNS numeric
    LANGUAGE sql STABLE
    AS $$
   SELECT ROUND(COALESCE(fn_bill_total(p),0) - COALESCE(fn_total_paid(p),0), 2);
$$;


ALTER FUNCTION public.fn_balance_due(p bigint) OWNER TO postgres;

--
-- TOC entry 453 (class 1255 OID 17831)
-- Name: fn_bill_total(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_bill_total(p_booking_id bigint) RETURNS numeric
    LANGUAGE sql STABLE
    AS $$
  WITH base AS (
    SELECT
      COALESCE(fn_room_charges(b.booking_id),0) +
      COALESCE(fn_service_charges(b.booking_id),0) +
      b.late_fee_amount - b.discount_amount AS subtotal,
      b.tax_rate_percent
    FROM booking b WHERE b.booking_id = p_booking_id
  )
  SELECT ROUND(subtotal * (1 + tax_rate_percent/100.0),2) FROM base;
$$;


ALTER FUNCTION public.fn_bill_total(p_booking_id bigint) OWNER TO postgres;

--
-- TOC entry 265 (class 1255 OID 17837)
-- Name: fn_net_balance(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_net_balance(p_booking_id bigint) RETURNS numeric
    LANGUAGE sql STABLE
    AS $$
  SELECT ROUND(
    COALESCE(fn_bill_total(p_booking_id),0)
    - (COALESCE(fn_total_paid(p_booking_id),0) - COALESCE(fn_total_refunds(p_booking_id),0))
  , 2);
$$;


ALTER FUNCTION public.fn_net_balance(p_booking_id bigint) OWNER TO postgres;

--
-- TOC entry 377 (class 1255 OID 17828)
-- Name: fn_room_charges(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_room_charges(p_booking_id bigint) RETURNS numeric
    LANGUAGE sql STABLE
    AS $$
  SELECT GREATEST((b.check_out_date - b.check_in_date),0)::int * b.booked_rate
  FROM booking b WHERE b.booking_id = p_booking_id;
$$;


ALTER FUNCTION public.fn_room_charges(p_booking_id bigint) OWNER TO postgres;

--
-- TOC entry 408 (class 1255 OID 17829)
-- Name: fn_service_charges(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_service_charges(p_booking_id bigint) RETURNS numeric
    LANGUAGE sql STABLE
    AS $$
  SELECT COALESCE(SUM(u.qty * u.unit_price_at_use),0)
  FROM service_usage u WHERE u.booking_id = p_booking_id;
$$;


ALTER FUNCTION public.fn_service_charges(p_booking_id bigint) OWNER TO postgres;

--
-- TOC entry 272 (class 1255 OID 17830)
-- Name: fn_total_paid(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_total_paid(p_booking_id bigint) RETURNS numeric
    LANGUAGE sql STABLE
    AS $$
  SELECT COALESCE(SUM(p.amount),0) FROM payment p WHERE p.booking_id = p_booking_id;
$$;


ALTER FUNCTION public.fn_total_paid(p_booking_id bigint) OWNER TO postgres;

--
-- TOC entry 283 (class 1255 OID 17832)
-- Name: fn_total_refunds(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_total_refunds(p_booking_id bigint) RETURNS numeric
    LANGUAGE sql STABLE
    AS $$
  SELECT COALESCE(SUM(amount),0)
  FROM payment_adjustment
  WHERE booking_id = p_booking_id AND type IN ('refund','chargeback');
$$;


ALTER FUNCTION public.fn_total_refunds(p_booking_id bigint) OWNER TO postgres;

--
-- TOC entry 459 (class 1255 OID 17776)
-- Name: randn(numeric); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.randn(p numeric) RETURNS numeric
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT (random() * p)::numeric;
$$;


ALTER FUNCTION public.randn(p numeric) OWNER TO postgres;

--
-- TOC entry 397 (class 1255 OID 17838)
-- Name: sp_cancel_booking(bigint, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sp_cancel_booking(p_booking_id bigint, p_reference_note character varying DEFAULT NULL::character varying) RETURNS TABLE(booking_id bigint, bill_total numeric, total_paid numeric, cancellation_fee numeric, refund_amount numeric, status_after text)
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_bill   NUMERIC;
  v_paid   NUMERIC;
  v_fee    NUMERIC := 0;
  v_refund NUMERIC := 0;
  v_checkin DATE;
  v_today   DATE := CURRENT_DATE;
  v_status  booking_status;
BEGIN
  -- 1) Load current facts
  SELECT check_in_date, status INTO v_checkin, v_status
  FROM booking WHERE booking_id = p_booking_id FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking % not found', p_booking_id;
  END IF;

  v_bill := COALESCE(fn_bill_total(p_booking_id),0);
  v_paid := COALESCE(fn_total_paid(p_booking_id),0);

  -- 2) Policy: free >= 2 days before check-in; else 10% fee
  IF v_checkin - v_today >= 2 THEN
    v_fee := 0;
  ELSE
    v_fee := ROUND(v_bill * 0.10, 2);  -- 10% fee
  END IF;

  -- Never refund more than bill total minus fee (and not more than paid)
  v_refund := GREATEST(LEAST(v_paid, GREATEST(v_bill - v_fee, 0)), 0);

  -- 3) Record refund only if there is something to refund
  IF v_refund > 0 THEN
    INSERT INTO payment_adjustment (booking_id, amount, type, reference_note)
    VALUES (p_booking_id, v_refund, 'refund', COALESCE(p_reference_note, 'auto-refund on cancel'));
  END IF;

  -- 4) Set status to Cancelled (idempotent)
  UPDATE booking
  SET status = 'Cancelled'
  WHERE booking_id = p_booking_id;

  -- 5) Return a summary row
  RETURN QUERY
  SELECT p_booking_id, v_bill, v_paid, v_fee, v_refund, 'Cancelled'::text;
END $$;


ALTER FUNCTION public.sp_cancel_booking(p_booking_id bigint, p_reference_note character varying) OWNER TO postgres;

--
-- TOC entry 349 (class 1255 OID 17854)
-- Name: trg_check_min_advance(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trg_check_min_advance() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_required numeric(10,2);
BEGIN
  v_required := ROUND(
    (GREATEST((NEW.check_out_date - NEW.check_in_date), 0)::int * NEW.booked_rate) * 0.10, 2
  );

  IF NEW.advance_payment < v_required THEN
    RAISE EXCEPTION
      'advance_payment (%.2f) is below the required 10%% (%.2f) of room charges (nights × rate)',
      NEW.advance_payment, v_required
      USING ERRCODE = '23514';  -- check_violation
  END IF;

  RETURN NEW;
END $$;


ALTER FUNCTION public.trg_check_min_advance() OWNER TO postgres;

--
-- TOC entry 291 (class 1255 OID 17839)
-- Name: trg_refund_advance_on_cancel(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trg_refund_advance_on_cancel() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_adv NUMERIC;
BEGIN
  IF NEW.status = 'Cancelled' AND OLD.status <> 'Cancelled' THEN
    v_adv := COALESCE(NEW.advance_payment,0);
    IF v_adv > 0 THEN
      INSERT INTO payment_adjustment (booking_id, amount, type, reference_note)
      VALUES (NEW.booking_id, v_adv, 'refund', 'Auto refund of advance on cancel');
    END IF;
  END IF;
  RETURN NEW;
END $$;


ALTER FUNCTION public.trg_refund_advance_on_cancel() OWNER TO postgres;

--
-- TOC entry 365 (class 1255 OID 17844)
-- Name: trg_refund_advance_policy(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trg_refund_advance_policy() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_checkin  DATE;
  v_today    DATE := CURRENT_DATE;
  v_adv      NUMERIC;
  v_fee      NUMERIC;
  v_refund   NUMERIC;
BEGIN
  -- Run only when status just changed to Cancelled
  IF NEW.status = 'Cancelled' AND OLD.status <> 'Cancelled' THEN
    v_checkin := NEW.check_in_date;
    v_adv     := COALESCE(NEW.advance_payment,0);

    IF v_adv > 0 THEN
      -- Rule: full refund if ≥2 days before check-in, else 10 % fee
      IF v_checkin - v_today >= 2 THEN
        v_fee := 0;
      ELSE
        v_fee := ROUND(v_adv * 0.10,2);     -- 10 % fee
      END IF;

      v_refund := GREATEST(v_adv - v_fee,0);

      INSERT INTO payment_adjustment(booking_id,amount,type,reference_note)
      VALUES(NEW.booking_id,v_refund,'refund',
             CASE WHEN v_fee=0
                  THEN 'Full advance refund (≥2 days before check-in)'
                  ELSE 'Refund after 10 % late-cancel fee'
             END);
    END IF;
  END IF;

  RETURN NEW;
END $$;


ALTER FUNCTION public.trg_refund_advance_policy() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 249 (class 1259 OID 17778)
-- Name: audit_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.audit_log (
    audit_id integer NOT NULL,
    actor text NOT NULL,
    action text NOT NULL,
    entity text NOT NULL,
    entity_id bigint,
    details jsonb,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.audit_log OWNER TO postgres;

--
-- TOC entry 248 (class 1259 OID 17777)
-- Name: audit_log_audit_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.audit_log_audit_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.audit_log_audit_id_seq OWNER TO postgres;

--
-- TOC entry 5427 (class 0 OID 0)
-- Dependencies: 248
-- Name: audit_log_audit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.audit_log_audit_id_seq OWNED BY public.audit_log.audit_id;


--
-- TOC entry 239 (class 1259 OID 16538)
-- Name: booking; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.booking (
    booking_id bigint NOT NULL,
    pre_booking_id bigint,
    guest_id bigint NOT NULL,
    room_id bigint NOT NULL,
    check_in_date date NOT NULL,
    check_out_date date NOT NULL,
    status public.booking_status DEFAULT 'Booked'::public.booking_status NOT NULL,
    booked_rate numeric(10,2) NOT NULL,
    tax_rate_percent numeric(5,2) DEFAULT 0 NOT NULL,
    discount_amount numeric(10,2) DEFAULT 0 NOT NULL,
    late_fee_amount numeric(10,2) DEFAULT 0 NOT NULL,
    preferred_payment_method public.payment_method,
    advance_payment numeric(10,2) DEFAULT 0 NOT NULL,
    room_estimate numeric(10,2) GENERATED ALWAYS AS (((GREATEST((check_out_date - check_in_date), 0))::numeric * booked_rate)) STORED,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT booking_advance_min_10pct CHECK (((advance_payment + 0.005) >= round((((GREATEST((check_out_date - check_in_date), 0))::numeric * booked_rate) * 0.10), 2)))
);


ALTER TABLE public.booking OWNER TO postgres;

--
-- TOC entry 238 (class 1259 OID 16537)
-- Name: booking_booking_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.booking_booking_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.booking_booking_id_seq OWNER TO postgres;

--
-- TOC entry 5428 (class 0 OID 0)
-- Dependencies: 238
-- Name: booking_booking_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.booking_booking_id_seq OWNED BY public.booking.booking_id;


--
-- TOC entry 219 (class 1259 OID 16389)
-- Name: branch; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.branch (
    branch_id bigint NOT NULL,
    branch_name character varying(100) NOT NULL,
    contact_number character varying(30),
    address text,
    manager_name character varying(100),
    branch_code character varying(10)
);


ALTER TABLE public.branch OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 16388)
-- Name: branch_branch_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.branch_branch_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.branch_branch_id_seq OWNER TO postgres;

--
-- TOC entry 5429 (class 0 OID 0)
-- Dependencies: 218
-- Name: branch_branch_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.branch_branch_id_seq OWNED BY public.branch.branch_id;


--
-- TOC entry 235 (class 1259 OID 16519)
-- Name: customer; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.customer (
    customer_id bigint NOT NULL,
    user_id bigint,
    guest_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.customer OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 16518)
-- Name: customer_customer_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.customer_customer_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.customer_customer_id_seq OWNER TO postgres;

--
-- TOC entry 5430 (class 0 OID 0)
-- Dependencies: 234
-- Name: customer_customer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.customer_customer_id_seq OWNED BY public.customer.customer_id;


--
-- TOC entry 233 (class 1259 OID 16508)
-- Name: employee; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.employee (
    employee_id bigint NOT NULL,
    user_id bigint NOT NULL,
    branch_id bigint NOT NULL,
    name character varying(120) NOT NULL,
    email character varying(150),
    contact_no character varying(30)
);


ALTER TABLE public.employee OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 16507)
-- Name: employee_employee_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.employee_employee_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.employee_employee_id_seq OWNER TO postgres;

--
-- TOC entry 5431 (class 0 OID 0)
-- Dependencies: 232
-- Name: employee_employee_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.employee_employee_id_seq OWNED BY public.employee.employee_id;


--
-- TOC entry 229 (class 1259 OID 16484)
-- Name: guest; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.guest (
    guest_id bigint NOT NULL,
    nic character varying(30),
    full_name character varying(120) NOT NULL,
    email character varying(150),
    phone character varying(30),
    gender character varying(20),
    date_of_birth date,
    address text,
    nationality character varying(80)
);


ALTER TABLE public.guest OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 16483)
-- Name: guest_guest_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.guest_guest_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.guest_guest_id_seq OWNER TO postgres;

--
-- TOC entry 5432 (class 0 OID 0)
-- Dependencies: 228
-- Name: guest_guest_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.guest_guest_id_seq OWNED BY public.guest.guest_id;


--
-- TOC entry 221 (class 1259 OID 16448)
-- Name: invoice; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.invoice (
    invoice_id bigint NOT NULL,
    booking_id bigint NOT NULL,
    period_start date,
    period_end date,
    issued_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.invoice OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 16447)
-- Name: invoice_invoice_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.invoice_invoice_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.invoice_invoice_id_seq OWNER TO postgres;

--
-- TOC entry 5433 (class 0 OID 0)
-- Dependencies: 220
-- Name: invoice_invoice_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.invoice_invoice_id_seq OWNED BY public.invoice.invoice_id;


--
-- TOC entry 223 (class 1259 OID 16456)
-- Name: payment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.payment (
    payment_id bigint NOT NULL,
    booking_id bigint NOT NULL,
    amount numeric(10,2) NOT NULL,
    method public.payment_method,
    paid_at timestamp with time zone DEFAULT now() NOT NULL,
    payment_reference character varying(100)
);


ALTER TABLE public.payment OWNER TO postgres;

--
-- TOC entry 252 (class 1259 OID 17814)
-- Name: payment_adjustment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.payment_adjustment (
    adjustment_id bigint NOT NULL,
    booking_id bigint NOT NULL,
    amount numeric(10,2) NOT NULL,
    type public.adjustment_type NOT NULL,
    reference_note character varying(200),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT payment_adjustment_amount_check CHECK ((amount > (0)::numeric))
);


ALTER TABLE public.payment_adjustment OWNER TO postgres;

--
-- TOC entry 251 (class 1259 OID 17813)
-- Name: payment_adjustment_adjustment_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.payment_adjustment_adjustment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.payment_adjustment_adjustment_id_seq OWNER TO postgres;

--
-- TOC entry 5434 (class 0 OID 0)
-- Dependencies: 251
-- Name: payment_adjustment_adjustment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.payment_adjustment_adjustment_id_seq OWNED BY public.payment_adjustment.adjustment_id;


--
-- TOC entry 222 (class 1259 OID 16455)
-- Name: payment_payment_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.payment_payment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.payment_payment_id_seq OWNER TO postgres;

--
-- TOC entry 5435 (class 0 OID 0)
-- Dependencies: 222
-- Name: payment_payment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.payment_payment_id_seq OWNED BY public.payment.payment_id;


--
-- TOC entry 237 (class 1259 OID 16531)
-- Name: pre_booking; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pre_booking (
    pre_booking_id bigint NOT NULL,
    guest_id bigint NOT NULL,
    capacity integer NOT NULL,
    prebooking_method public.prebooking_method NOT NULL,
    expected_check_in date NOT NULL,
    expected_check_out date NOT NULL,
    room_id bigint,
    created_by_employee_id bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.pre_booking OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 16530)
-- Name: pre_booking_pre_booking_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pre_booking_pre_booking_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pre_booking_pre_booking_id_seq OWNER TO postgres;

--
-- TOC entry 5436 (class 0 OID 0)
-- Dependencies: 236
-- Name: pre_booking_pre_booking_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pre_booking_pre_booking_id_seq OWNED BY public.pre_booking.pre_booking_id;


--
-- TOC entry 225 (class 1259 OID 16464)
-- Name: room; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.room (
    room_id bigint NOT NULL,
    branch_id bigint NOT NULL,
    room_type_id bigint NOT NULL,
    room_number character varying(20) NOT NULL,
    status public.room_status DEFAULT 'Available'::public.room_status NOT NULL
);


ALTER TABLE public.room OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 16463)
-- Name: room_room_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.room_room_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.room_room_id_seq OWNER TO postgres;

--
-- TOC entry 5437 (class 0 OID 0)
-- Dependencies: 224
-- Name: room_room_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.room_room_id_seq OWNED BY public.room.room_id;


--
-- TOC entry 227 (class 1259 OID 16473)
-- Name: room_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.room_type (
    room_type_id bigint NOT NULL,
    name character varying(50) NOT NULL,
    capacity integer NOT NULL,
    daily_rate numeric(10,2) NOT NULL,
    amenities text
);


ALTER TABLE public.room_type OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 16472)
-- Name: room_type_room_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.room_type_room_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.room_type_room_type_id_seq OWNER TO postgres;

--
-- TOC entry 5438 (class 0 OID 0)
-- Dependencies: 226
-- Name: room_type_room_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.room_type_room_type_id_seq OWNED BY public.room_type.room_type_id;


--
-- TOC entry 241 (class 1259 OID 16549)
-- Name: service_catalog; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.service_catalog (
    service_id bigint NOT NULL,
    code character varying(30),
    name character varying(100) NOT NULL,
    category character varying(60),
    unit_price numeric(10,2) NOT NULL,
    tax_rate_percent numeric(5,2) DEFAULT 0 NOT NULL,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.service_catalog OWNER TO postgres;

--
-- TOC entry 240 (class 1259 OID 16548)
-- Name: service_catalog_service_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.service_catalog_service_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.service_catalog_service_id_seq OWNER TO postgres;

--
-- TOC entry 5439 (class 0 OID 0)
-- Dependencies: 240
-- Name: service_catalog_service_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.service_catalog_service_id_seq OWNED BY public.service_catalog.service_id;


--
-- TOC entry 243 (class 1259 OID 16560)
-- Name: service_usage; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.service_usage (
    service_usage_id bigint NOT NULL,
    booking_id bigint NOT NULL,
    service_id bigint NOT NULL,
    used_on date DEFAULT CURRENT_DATE NOT NULL,
    qty integer NOT NULL,
    unit_price_at_use numeric(10,2) NOT NULL
);


ALTER TABLE public.service_usage OWNER TO postgres;

--
-- TOC entry 242 (class 1259 OID 16559)
-- Name: service_usage_service_usage_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.service_usage_service_usage_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.service_usage_service_usage_id_seq OWNER TO postgres;

--
-- TOC entry 5440 (class 0 OID 0)
-- Dependencies: 242
-- Name: service_usage_service_usage_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.service_usage_service_usage_id_seq OWNED BY public.service_usage.service_usage_id;


--
-- TOC entry 231 (class 1259 OID 16495)
-- Name: user_account; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_account (
    user_id bigint NOT NULL,
    username character varying(60) NOT NULL,
    password_hash character varying(100) NOT NULL,
    role public.user_role NOT NULL,
    guest_id bigint
);


ALTER TABLE public.user_account OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 16494)
-- Name: user_account_user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_account_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_account_user_id_seq OWNER TO postgres;

--
-- TOC entry 5441 (class 0 OID 0)
-- Dependencies: 230
-- Name: user_account_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_account_user_id_seq OWNED BY public.user_account.user_id;


--
-- TOC entry 250 (class 1259 OID 17801)
-- Name: vw_billing_summary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_billing_summary AS
 WITH calc AS (
         SELECT b_1.booking_id,
            (b_1.check_out_date - b_1.check_in_date) AS nights,
            (((b_1.check_out_date - b_1.check_in_date))::numeric * b_1.booked_rate) AS room_total,
            COALESCE(sum(((u.qty)::numeric * u.unit_price_at_use)), (0)::numeric) AS service_total,
            b_1.discount_amount,
            b_1.late_fee_amount,
            b_1.tax_rate_percent
           FROM (public.booking b_1
             LEFT JOIN public.service_usage u ON ((u.booking_id = b_1.booking_id)))
          GROUP BY b_1.booking_id, (b_1.check_out_date - b_1.check_in_date), (((b_1.check_out_date - b_1.check_in_date))::numeric * b_1.booked_rate), b_1.discount_amount, b_1.late_fee_amount, b_1.tax_rate_percent
        ), paid AS (
         SELECT payment.booking_id,
            COALESCE(sum(payment.amount), (0)::numeric) AS total_paid
           FROM public.payment
          GROUP BY payment.booking_id
        )
 SELECT b.booking_id,
    g.full_name AS guest,
    br.branch_name,
    r.room_number,
    c.nights,
    c.room_total,
    c.service_total,
    round(((((c.room_total + c.service_total) + b.late_fee_amount) - b.discount_amount) * ((1)::numeric + (b.tax_rate_percent / 100.0))), 2) AS total_bill,
    COALESCE(p.total_paid, (0)::numeric) AS total_paid,
    round((((((c.room_total + c.service_total) + b.late_fee_amount) - b.discount_amount) * ((1)::numeric + (b.tax_rate_percent / 100.0))) - COALESCE(p.total_paid, (0)::numeric)), 2) AS balance_due,
    b.status
   FROM (((((calc c
     JOIN public.booking b ON ((b.booking_id = c.booking_id)))
     JOIN public.guest g ON ((g.guest_id = b.guest_id)))
     JOIN public.room r ON ((r.room_id = b.room_id)))
     JOIN public.branch br ON ((br.branch_id = r.branch_id)))
     LEFT JOIN paid p ON ((p.booking_id = b.booking_id)));


ALTER VIEW public.vw_billing_summary OWNER TO postgres;

--
-- TOC entry 245 (class 1259 OID 17321)
-- Name: vw_service_usage_detail; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_service_usage_detail AS
 SELECT u.service_usage_id,
    u.used_on,
    br.branch_name,
    r.room_number,
    b.booking_id,
    sc.code AS service_code,
    sc.name AS service_name,
    u.qty,
    u.unit_price_at_use,
    ((u.qty)::numeric * u.unit_price_at_use) AS line_total
   FROM ((((public.service_usage u
     JOIN public.booking b ON ((b.booking_id = u.booking_id)))
     JOIN public.room r ON ((r.room_id = b.room_id)))
     JOIN public.branch br ON ((br.branch_id = r.branch_id)))
     JOIN public.service_catalog sc ON ((sc.service_id = u.service_id)));


ALTER VIEW public.vw_service_usage_detail OWNER TO postgres;

--
-- TOC entry 246 (class 1259 OID 17326)
-- Name: vw_branch_revenue_monthly; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_branch_revenue_monthly AS
 WITH room_days AS (
         SELECT br.branch_name,
            (date_trunc('day'::text, dd.dd))::date AS day,
            b.booking_id,
            (b.booked_rate)::numeric AS room_rate
           FROM (((public.booking b
             JOIN public.room r ON ((r.room_id = b.room_id)))
             JOIN public.branch br ON ((br.branch_id = r.branch_id)))
             JOIN LATERAL generate_series((b.check_in_date)::timestamp without time zone, (b.check_out_date - '1 day'::interval), '1 day'::interval) dd(dd) ON (true))
          WHERE (b.status = ANY (ARRAY['Booked'::public.booking_status, 'Checked-In'::public.booking_status, 'Checked-Out'::public.booking_status]))
        ), room_month AS (
         SELECT (date_trunc('month'::text, (room_days.day)::timestamp with time zone))::date AS month,
            room_days.branch_name,
            count(*) AS nights_in_month,
            sum(room_days.room_rate) AS room_revenue
           FROM room_days
          GROUP BY ((date_trunc('month'::text, (room_days.day)::timestamp with time zone))::date), room_days.branch_name
        ), service_month AS (
         SELECT (date_trunc('month'::text, (d.used_on)::timestamp with time zone))::date AS month,
            br.branch_name,
            COALESCE(sum(d.line_total), (0)::numeric) AS service_revenue
           FROM (public.vw_service_usage_detail d
             JOIN public.branch br ON (((br.branch_name)::text = (d.branch_name)::text)))
          GROUP BY ((date_trunc('month'::text, (d.used_on)::timestamp with time zone))::date), br.branch_name
        )
 SELECT COALESCE(rm.month, sm.month) AS month,
    COALESCE(rm.branch_name, sm.branch_name) AS branch_name,
    COALESCE(rm.nights_in_month, (0)::bigint) AS nights_in_month,
    COALESCE(rm.room_revenue, (0)::numeric) AS room_revenue,
    COALESCE(sm.service_revenue, (0)::numeric) AS service_revenue,
    (COALESCE(rm.room_revenue, (0)::numeric) + COALESCE(sm.service_revenue, (0)::numeric)) AS total_revenue
   FROM (room_month rm
     FULL JOIN service_month sm ON (((sm.month = rm.month) AND ((sm.branch_name)::text = (rm.branch_name)::text))));


ALTER VIEW public.vw_branch_revenue_monthly OWNER TO postgres;

--
-- TOC entry 244 (class 1259 OID 17311)
-- Name: vw_occupancy_by_day; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_occupancy_by_day AS
 SELECT (d.day)::date AS day,
    br.branch_name,
    r.room_number,
    b.booking_id,
    g.full_name AS guest,
    b.status
   FROM ((((public.booking b
     JOIN public.room r ON ((r.room_id = b.room_id)))
     JOIN public.branch br ON ((br.branch_id = r.branch_id)))
     JOIN public.guest g ON ((g.guest_id = b.guest_id)))
     JOIN LATERAL generate_series((b.check_in_date)::timestamp without time zone, (b.check_out_date - '1 day'::interval), '1 day'::interval) d(day) ON (true))
  WHERE (b.status = ANY (ARRAY['Booked'::public.booking_status, 'Checked-In'::public.booking_status, 'Checked-Out'::public.booking_status]));


ALTER VIEW public.vw_occupancy_by_day OWNER TO postgres;

--
-- TOC entry 247 (class 1259 OID 17331)
-- Name: vw_service_monthly_trend; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_service_monthly_trend AS
 SELECT (date_trunc('month'::text, (used_on)::timestamp with time zone))::date AS month,
    service_code,
    service_name,
    sum(qty) AS total_qty,
    sum(line_total) AS total_revenue
   FROM public.vw_service_usage_detail
  GROUP BY ((date_trunc('month'::text, (used_on)::timestamp with time zone))::date), service_code, service_name;


ALTER VIEW public.vw_service_monthly_trend OWNER TO postgres;

--
-- TOC entry 5155 (class 2604 OID 17781)
-- Name: audit_log audit_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_log ALTER COLUMN audit_id SET DEFAULT nextval('public.audit_log_audit_id_seq'::regclass);


--
-- TOC entry 5142 (class 2604 OID 16541)
-- Name: booking booking_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.booking ALTER COLUMN booking_id SET DEFAULT nextval('public.booking_booking_id_seq'::regclass);


--
-- TOC entry 5127 (class 2604 OID 16392)
-- Name: branch branch_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.branch ALTER COLUMN branch_id SET DEFAULT nextval('public.branch_branch_id_seq'::regclass);


--
-- TOC entry 5138 (class 2604 OID 16522)
-- Name: customer customer_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer ALTER COLUMN customer_id SET DEFAULT nextval('public.customer_customer_id_seq'::regclass);


--
-- TOC entry 5137 (class 2604 OID 16511)
-- Name: employee employee_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee ALTER COLUMN employee_id SET DEFAULT nextval('public.employee_employee_id_seq'::regclass);


--
-- TOC entry 5135 (class 2604 OID 16487)
-- Name: guest guest_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.guest ALTER COLUMN guest_id SET DEFAULT nextval('public.guest_guest_id_seq'::regclass);


--
-- TOC entry 5128 (class 2604 OID 16451)
-- Name: invoice invoice_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoice ALTER COLUMN invoice_id SET DEFAULT nextval('public.invoice_invoice_id_seq'::regclass);


--
-- TOC entry 5130 (class 2604 OID 16459)
-- Name: payment payment_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment ALTER COLUMN payment_id SET DEFAULT nextval('public.payment_payment_id_seq'::regclass);


--
-- TOC entry 5157 (class 2604 OID 17817)
-- Name: payment_adjustment adjustment_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment_adjustment ALTER COLUMN adjustment_id SET DEFAULT nextval('public.payment_adjustment_adjustment_id_seq'::regclass);


--
-- TOC entry 5140 (class 2604 OID 16534)
-- Name: pre_booking pre_booking_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pre_booking ALTER COLUMN pre_booking_id SET DEFAULT nextval('public.pre_booking_pre_booking_id_seq'::regclass);


--
-- TOC entry 5132 (class 2604 OID 16467)
-- Name: room room_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.room ALTER COLUMN room_id SET DEFAULT nextval('public.room_room_id_seq'::regclass);


--
-- TOC entry 5134 (class 2604 OID 16476)
-- Name: room_type room_type_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.room_type ALTER COLUMN room_type_id SET DEFAULT nextval('public.room_type_room_type_id_seq'::regclass);


--
-- TOC entry 5150 (class 2604 OID 16552)
-- Name: service_catalog service_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_catalog ALTER COLUMN service_id SET DEFAULT nextval('public.service_catalog_service_id_seq'::regclass);


--
-- TOC entry 5153 (class 2604 OID 16563)
-- Name: service_usage service_usage_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_usage ALTER COLUMN service_usage_id SET DEFAULT nextval('public.service_usage_service_usage_id_seq'::regclass);


--
-- TOC entry 5136 (class 2604 OID 16498)
-- Name: user_account user_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_account ALTER COLUMN user_id SET DEFAULT nextval('public.user_account_user_id_seq'::regclass);


--
-- TOC entry 5417 (class 0 OID 17778)
-- Dependencies: 249
-- Data for Name: audit_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.audit_log VALUES (1, 'admin', 'UPDATE', 'payment', 728, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (2, 'recept_kandy', 'UPDATE', 'service_usage', 813, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (3, 'manager_col', 'INSERT', 'service_usage', 278, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (4, 'recept_kandy', 'UPDATE', 'payment', 467, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (5, 'manager_col', 'INSERT', 'booking', 892, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (6, 'acc_galle', 'DELETE', 'payment', 584, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (7, 'recept_kandy', 'UPDATE', 'payment', 357, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (8, 'acc_galle', 'UPDATE', 'payment', 392, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (9, 'recept_kandy', 'UPDATE', 'payment', 80, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (10, 'acc_galle', 'INSERT', 'service_usage', 485, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (11, 'manager_col', 'DELETE', 'service_usage', 33, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (12, 'acc_galle', 'INSERT', 'booking', 934, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (13, 'manager_col', 'INSERT', 'payment', 989, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (14, 'recept_kandy', 'INSERT', 'booking', 709, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (15, 'admin', 'UPDATE', 'service_usage', 932, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (16, 'recept_kandy', 'DELETE', 'payment', 227, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (17, 'acc_galle', 'UPDATE', 'payment', 581, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (18, 'manager_col', 'UPDATE', 'payment', 476, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (19, 'manager_col', 'UPDATE', 'booking', 825, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (20, 'recept_kandy', 'INSERT', 'payment', 483, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (21, 'recept_kandy', 'UPDATE', 'payment', 690, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (22, 'recept_kandy', 'INSERT', 'payment', 111, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (23, 'manager_col', 'INSERT', 'payment', 389, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (24, 'admin', 'INSERT', 'payment', 920, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (25, 'manager_col', 'UPDATE', 'booking', 286, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (26, 'recept_kandy', 'INSERT', 'booking', 561, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (27, 'manager_col', 'DELETE', 'booking', 351, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (28, 'manager_col', 'DELETE', 'booking', 73, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (29, 'recept_kandy', 'DELETE', 'payment', 26, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (30, 'manager_col', 'DELETE', 'payment', 124, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (31, 'manager_col', 'UPDATE', 'booking', 982, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (32, 'acc_galle', 'INSERT', 'service_usage', 36, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (33, 'recept_kandy', 'UPDATE', 'booking', 647, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (34, 'acc_galle', 'UPDATE', 'payment', 849, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (35, 'manager_col', 'INSERT', 'payment', 827, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (36, 'recept_kandy', 'UPDATE', 'service_usage', 163, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (37, 'admin', 'INSERT', 'payment', 327, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (38, 'recept_kandy', 'INSERT', 'payment', 350, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (39, 'manager_col', 'DELETE', 'payment', 836, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (40, 'manager_col', 'UPDATE', 'booking', 536, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (41, 'manager_col', 'DELETE', 'booking', 798, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (42, 'manager_col', 'UPDATE', 'service_usage', 385, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (43, 'manager_col', 'INSERT', 'payment', 861, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (44, 'acc_galle', 'INSERT', 'booking', 771, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (45, 'recept_kandy', 'UPDATE', 'booking', 623, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (46, 'recept_kandy', 'UPDATE', 'payment', 644, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (47, 'manager_col', 'UPDATE', 'payment', 582, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (48, 'acc_galle', 'INSERT', 'payment', 32, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (49, 'recept_kandy', 'DELETE', 'booking', 361, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (50, 'recept_kandy', 'UPDATE', 'booking', 278, '{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}', '2025-10-05 15:04:10.097053');
INSERT INTO public.audit_log VALUES (52, 'recept_kandy', 'DELETE', 'service_usage', 878, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (53, 'recept_kandy', 'DELETE', 'service_usage', 375, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (54, 'recept_kandy', 'DELETE', 'service_usage', 596, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (55, 'recept_kandy', 'DELETE', 'service_usage', 513, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (56, 'recept_kandy', 'DELETE', 'service_usage', 996, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (57, 'recept_kandy', 'DELETE', 'service_usage', 820, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (58, 'recept_kandy', 'DELETE', 'service_usage', 80, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (59, 'recept_kandy', 'DELETE', 'service_usage', 717, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (60, 'recept_kandy', 'DELETE', 'service_usage', 650, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (61, 'recept_kandy', 'DELETE', 'service_usage', 720, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (62, 'recept_kandy', 'DELETE', 'service_usage', 414, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (63, 'recept_kandy', 'DELETE', 'service_usage', 825, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (64, 'recept_kandy', 'DELETE', 'service_usage', 782, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (65, 'recept_kandy', 'DELETE', 'service_usage', 696, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (66, 'recept_kandy', 'DELETE', 'service_usage', 988, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (67, 'recept_kandy', 'DELETE', 'service_usage', 334, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (68, 'recept_kandy', 'DELETE', 'service_usage', 134, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (69, 'recept_kandy', 'DELETE', 'service_usage', 165, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (70, 'recept_kandy', 'DELETE', 'service_usage', 570, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (71, 'recept_kandy', 'DELETE', 'service_usage', 301, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (72, 'recept_kandy', 'DELETE', 'service_usage', 807, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (73, 'recept_kandy', 'DELETE', 'service_usage', 129, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (74, 'recept_kandy', 'DELETE', 'service_usage', 367, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (75, 'recept_kandy', 'DELETE', 'service_usage', 591, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (76, 'recept_kandy', 'DELETE', 'service_usage', 629, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (77, 'recept_kandy', 'DELETE', 'service_usage', 847, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (78, 'recept_kandy', 'DELETE', 'service_usage', 983, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (79, 'recept_kandy', 'DELETE', 'service_usage', 54, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (80, 'recept_kandy', 'DELETE', 'service_usage', 166, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (81, 'recept_kandy', 'DELETE', 'service_usage', 238, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (82, 'recept_kandy', 'DELETE', 'service_usage', 27, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (83, 'recept_kandy', 'DELETE', 'service_usage', 326, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (84, 'recept_kandy', 'DELETE', 'service_usage', 424, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (85, 'recept_kandy', 'DELETE', 'service_usage', 159, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (86, 'recept_kandy', 'DELETE', 'service_usage', 180, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (87, 'recept_kandy', 'DELETE', 'service_usage', 508, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (88, 'recept_kandy', 'DELETE', 'service_usage', 887, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (89, 'recept_kandy', 'DELETE', 'service_usage', 246, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (90, 'recept_kandy', 'DELETE', 'service_usage', 312, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (91, 'recept_kandy', 'DELETE', 'service_usage', 477, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (92, 'recept_kandy', 'DELETE', 'service_usage', 429, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (93, 'recept_kandy', 'DELETE', 'service_usage', 194, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (94, 'recept_kandy', 'DELETE', 'service_usage', 493, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (95, 'recept_kandy', 'DELETE', 'service_usage', 950, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (96, 'recept_kandy', 'DELETE', 'service_usage', 614, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (97, 'recept_kandy', 'DELETE', 'service_usage', 924, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (98, 'recept_kandy', 'DELETE', 'service_usage', 921, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (99, 'recept_kandy', 'DELETE', 'service_usage', 541, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (100, 'recept_kandy', 'DELETE', 'service_usage', 774, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');
INSERT INTO public.audit_log VALUES (101, 'recept_kandy', 'DELETE', 'service_usage', 243, '{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}', '2025-10-05 16:00:25.101475');


--
-- TOC entry 5411 (class 0 OID 16538)
-- Dependencies: 239
-- Data for Name: booking; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.booking VALUES (1426, NULL, 151, 11, '2025-10-10', '2025-10-14', 'Booked', 0.00, 0.00, 0.00, 0.00, NULL, 0.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1427, NULL, 151, 31, '2025-10-10', '2025-10-14', 'Booked', 0.00, 0.00, 0.00, 0.00, NULL, 0.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1428, NULL, 151, 51, '2025-10-10', '2025-10-14', 'Booked', 0.00, 0.00, 0.00, 0.00, NULL, 0.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (2, NULL, 66, 1, '2025-07-05', '2025-07-08', 'Checked-Out', 43200.00, 10.00, 0.00, 0.00, 'Card', 12960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (3, NULL, 89, 1, '2025-07-08', '2025-07-13', 'Checked-In', 40000.00, 10.00, 0.00, 0.00, 'Cash', 20000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (868, NULL, 58, 37, '2025-09-05', '2025-09-06', 'Checked-Out', 14256.00, 10.00, 0.00, 2956.45, 'Online', 1425.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (887, NULL, 143, 38, '2025-08-08', '2025-08-12', 'Checked-Out', 14256.00, 10.00, 0.00, 2478.36, 'Card', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (889, NULL, 86, 38, '2025-08-16', '2025-08-17', 'Checked-In', 14256.00, 10.00, 0.00, 2484.40, 'Online', 1425.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1145, NULL, 16, 49, '2025-08-10', '2025-08-13', 'Checked-Out', 19800.00, 10.00, 2432.15, 2042.81, 'Cash', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (5, NULL, 114, 1, '2025-07-22', '2025-07-26', 'Booked', 40000.00, 10.00, 0.00, 0.00, 'Card', 16000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (14, NULL, 28, 1, '2025-08-30', '2025-08-31', 'Booked', 47520.00, 10.00, 0.00, 0.00, 'Cash', 4752.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (48, NULL, 122, 3, '2025-07-06', '2025-07-09', 'Booked', 40000.00, 10.00, 0.00, 0.00, 'Cash', 12000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (175, NULL, 93, 8, '2025-07-30', '2025-08-03', 'Booked', 24000.00, 10.00, 0.00, 0.00, 'Online', 9600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (293, NULL, 51, 13, '2025-08-01', '2025-08-04', 'Booked', 21384.00, 10.00, 0.00, 0.00, 'Online', 6415.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (298, NULL, 118, 13, '2025-08-23', '2025-08-26', 'Booked', 21384.00, 10.00, 0.00, 0.00, 'Card', 6415.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (316, NULL, 93, 14, '2025-08-11', '2025-08-13', 'Booked', 19800.00, 10.00, 2432.15, 0.00, 'Online', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (348, NULL, 138, 15, '2025-09-16', '2025-09-18', 'Booked', 19800.00, 10.00, 2666.03, 0.00, 'Online', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (366, NULL, 102, 16, '2025-08-14', '2025-08-17', 'Booked', 13200.00, 10.00, 0.00, 0.00, 'BankTransfer', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (377, NULL, 58, 16, '2025-09-25', '2025-09-28', 'Booked', 13200.00, 10.00, 0.00, 0.00, 'Cash', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (547, NULL, 8, 24, '2025-07-13', '2025-07-15', 'Booked', 24000.00, 10.00, 0.00, 4381.44, 'Card', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (551, NULL, 147, 24, '2025-07-24', '2025-07-26', 'Booked', 24000.00, 10.00, 2948.06, 0.00, 'Online', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (561, NULL, 34, 24, '2025-09-01', '2025-09-04', 'Booked', 26400.00, 10.00, 0.00, 0.00, 'BankTransfer', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (564, NULL, 97, 24, '2025-09-15', '2025-09-18', 'Booked', 26400.00, 10.00, 0.00, 0.00, 'Online', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (679, NULL, 43, 29, '2025-09-04', '2025-09-05', 'Booked', 19800.00, 10.00, 1388.24, 0.00, 'Card', 1980.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (687, NULL, 126, 30, '2025-07-03', '2025-07-04', 'Booked', 18000.00, 10.00, 956.92, 0.00, 'Card', 1800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (764, NULL, 54, 33, '2025-09-01', '2025-09-04', 'Booked', 19800.00, 10.00, 0.00, 4646.87, 'BankTransfer', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (843, NULL, 58, 36, '2025-08-28', '2025-09-02', 'Booked', 13200.00, 10.00, 0.00, 0.00, 'Online', 6600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (990, NULL, 39, 43, '2025-07-06', '2025-07-08', 'Booked', 40000.00, 10.00, 0.00, 0.00, 'BankTransfer', 8000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1003, NULL, 32, 43, '2025-08-29', '2025-09-01', 'Booked', 47520.00, 10.00, 0.00, 0.00, 'Card', 14256.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1009, NULL, 16, 43, '2025-09-20', '2025-09-23', 'Booked', 47520.00, 10.00, 5540.43, 0.00, 'Cash', 14256.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1018, NULL, 50, 44, '2025-07-29', '2025-08-02', 'Booked', 24000.00, 10.00, 0.00, 0.00, 'Cash', 9600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1030, NULL, 111, 44, '2025-09-16', '2025-09-18', 'Booked', 26400.00, 10.00, 3242.87, 0.00, 'BankTransfer', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1070, NULL, 117, 46, '2025-08-04', '2025-08-08', 'Booked', 26400.00, 10.00, 0.00, 0.00, 'Cash', 10560.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1073, NULL, 118, 46, '2025-08-12', '2025-08-16', 'Booked', 26400.00, 10.00, 0.00, 0.00, 'Online', 10560.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1088, NULL, 24, 47, '2025-07-17', '2025-07-20', 'Booked', 24000.00, 10.00, 0.00, 0.00, 'Online', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1213, NULL, 108, 52, '2025-08-01', '2025-08-06', 'Booked', 21384.00, 10.00, 1331.86, 0.00, 'BankTransfer', 10692.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1221, NULL, 108, 52, '2025-08-27', '2025-08-30', 'Booked', 19800.00, 10.00, 3349.15, 0.00, 'Online', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1306, NULL, 45, 56, '2025-07-28', '2025-07-30', 'Booked', 12000.00, 10.00, 0.00, 0.00, 'Online', 2400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1385, NULL, 130, 59, '2025-09-26', '2025-09-29', 'Booked', 14256.00, 10.00, 0.00, 0.00, 'Card', 4276.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1390, NULL, 130, 60, '2025-07-14', '2025-07-17', 'Booked', 12000.00, 10.00, 0.00, 0.00, 'Cash', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1398, NULL, 109, 60, '2025-08-15', '2025-08-18', 'Booked', 14256.00, 10.00, 0.00, 1905.08, 'Cash', 4276.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1411, NULL, 71, 32, '2025-10-22', '2025-10-24', 'Booked', 18000.00, 10.00, 0.00, 0.00, 'Online', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1414, NULL, 108, 56, '2025-10-11', '2025-10-13', 'Booked', 12000.00, 10.00, 0.00, 0.00, 'Card', 2400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1417, NULL, 107, 14, '2025-10-16', '2025-10-17', 'Booked', 18000.00, 10.00, 0.00, 0.00, 'BankTransfer', 1800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1419, NULL, 116, 41, '2025-10-16', '2025-10-19', 'Booked', 40000.00, 10.00, 0.00, 0.00, 'Card', 12000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1420, NULL, 81, 56, '2025-10-06', '2025-10-08', 'Booked', 12000.00, 10.00, 0.00, 0.00, 'Card', 2400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1421, NULL, 115, 35, '2025-10-22', '2025-10-25', 'Booked', 18000.00, 10.00, 0.00, 0.00, 'Online', 5400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1424, NULL, 72, 51, '2025-10-18', '2025-10-23', 'Booked', 18000.00, 10.00, 0.00, 0.00, 'Online', 9000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1412, NULL, 6, 54, '2025-10-19', '2025-10-22', 'Booked', 18000.00, 10.00, 3242.48, 0.00, 'Cash', 5400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1416, NULL, 92, 3, '2025-10-19', '2025-10-21', 'Booked', 40000.00, 10.00, 4828.13, 0.00, 'Cash', 8000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1418, NULL, 134, 16, '2025-10-10', '2025-10-13', 'Booked', 12000.00, 10.00, 925.30, 0.00, 'Cash', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1413, NULL, 103, 44, '2025-10-11', '2025-10-15', 'Booked', 24000.00, 10.00, 2948.06, 0.00, 'Cash', 9600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1423, NULL, 34, 43, '2025-10-19', '2025-10-21', 'Booked', 40000.00, 10.00, 3689.43, 10867.70, 'Cash', 8000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1415, NULL, 22, 56, '2025-10-18', '2025-10-23', 'Booked', 12000.00, 10.00, 1474.03, 2882.54, 'Cash', 6000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (619, NULL, 36, 27, '2025-07-24', '2025-07-26', 'Booked', 24000.00, 10.00, 2743.83, 0.00, 'Online', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (620, NULL, 120, 27, '2025-07-27', '2025-07-30', 'Booked', 24000.00, 10.00, 2378.90, 0.00, 'BankTransfer', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (922, NULL, 31, 40, '2025-07-01', '2025-07-03', 'Booked', 12000.00, 10.00, 2190.04, 0.00, 'Online', 2400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1236, NULL, 16, 53, '2025-07-28', '2025-08-01', 'Booked', 18000.00, 10.00, 3141.09, 0.00, 'Card', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1320, NULL, 108, 56, '2025-09-30', '2025-10-04', 'Booked', 13200.00, 10.00, 1147.84, 1338.08, 'BankTransfer', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (77, NULL, 119, 4, '2025-07-20', '2025-07-23', 'Booked', 24000.00, 10.00, 3054.97, 0.00, 'Cash', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1422, NULL, 53, 17, '2025-10-08', '2025-10-11', 'Booked', 12000.00, 10.00, 927.23, 0.00, 'Online', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (452, NULL, 119, 20, '2025-07-07', '2025-07-11', 'Booked', 12000.00, 10.00, 2173.13, 0.00, 'Online', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1431, NULL, 1, 1, '2025-11-10', '2025-11-12', 'Booked', 20000.00, 10.00, 0.00, 0.00, NULL, 4000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1429, NULL, 1, 1, '2025-10-10', '2025-10-12', 'Booked', 15000.00, 10.00, 0.00, 0.00, NULL, 20000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1430, NULL, 2, 2, '2025-10-06', '2025-10-08', 'Booked', 15000.00, 10.00, 0.00, 0.00, NULL, 20000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (91, NULL, 135, 4, '2025-09-19', '2025-09-20', 'Checked-In', 28512.00, 10.00, 0.00, 0.00, 'Online', 2851.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (4, NULL, 83, 1, '2025-07-15', '2025-07-20', 'Checked-In', 40000.00, 10.00, 0.00, 0.00, 'Card', 20000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (6, NULL, 136, 1, '2025-07-26', '2025-07-31', 'Checked-In', 43200.00, 10.00, 0.00, 0.00, 'Card', 21600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (9, NULL, 65, 1, '2025-08-08', '2025-08-12', 'Checked-Out', 47520.00, 10.00, 0.00, 0.00, 'Card', 19008.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (10, NULL, 74, 1, '2025-08-13', '2025-08-16', 'Checked-Out', 44000.00, 10.00, 0.00, 0.00, 'Card', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (11, NULL, 7, 1, '2025-08-17', '2025-08-21', 'Checked-In', 44000.00, 10.00, 0.00, 0.00, 'Online', 17600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (12, NULL, 132, 1, '2025-08-23', '2025-08-27', 'Checked-Out', 47520.00, 10.00, 0.00, 0.00, 'Cash', 19008.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (13, NULL, 74, 1, '2025-08-29', '2025-08-30', 'Checked-In', 47520.00, 10.00, 0.00, 0.00, 'Online', 4752.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (18, NULL, 125, 1, '2025-09-16', '2025-09-20', 'Checked-Out', 44000.00, 10.00, 0.00, 0.00, 'Card', 17600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (19, NULL, 133, 1, '2025-09-20', '2025-09-21', 'Checked-Out', 47520.00, 10.00, 0.00, 0.00, 'BankTransfer', 4752.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (22, NULL, 1, 2, '2025-07-01', '2025-07-04', 'Checked-Out', 40000.00, 10.00, 0.00, 0.00, 'BankTransfer', 12000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (23, NULL, 132, 2, '2025-07-04', '2025-07-08', 'Checked-Out', 43200.00, 10.00, 0.00, 0.00, 'BankTransfer', 17280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (26, NULL, 150, 2, '2025-07-16', '2025-07-18', 'Checked-Out', 40000.00, 10.00, 0.00, 0.00, 'Cash', 8000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (27, NULL, 139, 2, '2025-07-20', '2025-07-24', 'Checked-Out', 40000.00, 10.00, 0.00, 0.00, 'Card', 16000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (29, NULL, 109, 2, '2025-07-28', '2025-07-30', 'Checked-Out', 40000.00, 10.00, 0.00, 0.00, 'Cash', 8000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (30, NULL, 67, 2, '2025-08-01', '2025-08-02', 'Checked-Out', 47520.00, 10.00, 0.00, 0.00, 'Cash', 4752.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (31, NULL, 97, 2, '2025-08-02', '2025-08-05', 'Checked-Out', 47520.00, 10.00, 0.00, 0.00, 'Online', 14256.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (32, NULL, 70, 2, '2025-08-06', '2025-08-10', 'Checked-Out', 44000.00, 10.00, 0.00, 0.00, 'Online', 17600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (36, NULL, 41, 2, '2025-08-22', '2025-08-26', 'Checked-Out', 47520.00, 10.00, 0.00, 0.00, 'Card', 19008.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (37, NULL, 119, 2, '2025-08-26', '2025-08-29', 'Checked-In', 44000.00, 10.00, 0.00, 0.00, 'Card', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (38, NULL, 116, 2, '2025-08-31', '2025-09-02', 'Checked-Out', 44000.00, 10.00, 0.00, 0.00, 'Card', 8800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (39, NULL, 32, 2, '2025-09-04', '2025-09-06', 'Checked-Out', 44000.00, 10.00, 0.00, 0.00, 'Online', 8800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (40, NULL, 14, 2, '2025-09-07', '2025-09-10', 'Checked-Out', 44000.00, 10.00, 0.00, 0.00, 'Cash', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (41, NULL, 33, 2, '2025-09-12', '2025-09-16', 'Checked-Out', 47520.00, 10.00, 0.00, 0.00, 'Online', 19008.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (42, NULL, 30, 2, '2025-09-16', '2025-09-19', 'Checked-Out', 44000.00, 10.00, 0.00, 0.00, 'BankTransfer', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (43, NULL, 85, 2, '2025-09-19', '2025-09-22', 'Checked-Out', 47520.00, 10.00, 0.00, 0.00, 'Card', 14256.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (44, NULL, 84, 2, '2025-09-22', '2025-09-25', 'Checked-Out', 44000.00, 10.00, 0.00, 0.00, 'BankTransfer', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (45, NULL, 37, 2, '2025-09-26', '2025-09-29', 'Checked-Out', 47520.00, 10.00, 0.00, 0.00, 'Online', 14256.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (46, NULL, 14, 2, '2025-09-30', '2025-10-04', 'Checked-In', 44000.00, 10.00, 0.00, 0.00, 'Cash', 17600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (49, NULL, 92, 3, '2025-07-10', '2025-07-11', 'Checked-In', 40000.00, 10.00, 0.00, 0.00, 'Cash', 4000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (53, NULL, 62, 3, '2025-07-23', '2025-07-26', 'Checked-Out', 40000.00, 10.00, 0.00, 0.00, 'Online', 12000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (54, NULL, 88, 3, '2025-07-27', '2025-07-30', 'Checked-Out', 40000.00, 10.00, 0.00, 0.00, 'Card', 12000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (55, NULL, 18, 3, '2025-07-31', '2025-08-05', 'Checked-Out', 40000.00, 10.00, 0.00, 0.00, 'Online', 20000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (56, NULL, 76, 3, '2025-08-05', '2025-08-07', 'Checked-Out', 44000.00, 10.00, 0.00, 0.00, 'BankTransfer', 8800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (58, NULL, 13, 3, '2025-08-13', '2025-08-15', 'Checked-Out', 44000.00, 10.00, 0.00, 0.00, 'Card', 8800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (59, NULL, 102, 3, '2025-08-17', '2025-08-20', 'Checked-Out', 44000.00, 10.00, 0.00, 0.00, 'Online', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (62, NULL, 7, 3, '2025-08-28', '2025-09-01', 'Checked-Out', 44000.00, 10.00, 0.00, 0.00, 'BankTransfer', 17600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (68, NULL, 46, 3, '2025-09-26', '2025-09-27', 'Checked-Out', 47520.00, 10.00, 0.00, 0.00, 'Online', 4752.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (69, NULL, 58, 3, '2025-09-28', '2025-10-01', 'Checked-Out', 44000.00, 10.00, 0.00, 0.00, 'BankTransfer', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (70, NULL, 90, 4, '2025-07-01', '2025-07-04', 'Checked-Out', 24000.00, 10.00, 0.00, 0.00, 'Online', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (71, NULL, 102, 4, '2025-07-05', '2025-07-09', 'Checked-Out', 25920.00, 10.00, 0.00, 0.00, 'Cash', 10368.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (75, NULL, 96, 4, '2025-07-16', '2025-07-18', 'Checked-Out', 24000.00, 10.00, 0.00, 0.00, 'Online', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (80, NULL, 57, 4, '2025-08-04', '2025-08-06', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Online', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (81, NULL, 146, 4, '2025-08-08', '2025-08-11', 'Checked-Out', 28512.00, 10.00, 0.00, 0.00, 'BankTransfer', 8553.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (73, NULL, 60, 4, '2025-07-12', '2025-07-14', 'Checked-Out', 25920.00, 10.00, 3183.90, 0.00, 'Cash', 5184.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (16, NULL, 19, 1, '2025-09-06', '2025-09-11', 'Checked-Out', 47520.00, 10.00, 7197.75, 0.00, 'Online', 23760.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (24, NULL, 118, 2, '2025-07-09', '2025-07-12', 'Checked-Out', 40000.00, 10.00, 3239.52, 0.00, 'Online', 12000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (28, NULL, 94, 2, '2025-07-24', '2025-07-27', 'Checked-Out', 40000.00, 10.00, 6744.25, 0.00, 'Card', 12000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (17, NULL, 80, 1, '2025-09-11', '2025-09-15', 'Cancelled', 44000.00, 10.00, 0.00, 0.00, 'Cash', 17600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (35, NULL, 112, 2, '2025-08-18', '2025-08-21', 'Checked-Out', 44000.00, 10.00, 4928.22, 0.00, 'Cash', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (67, NULL, 127, 3, '2025-09-21', '2025-09-26', 'Checked-In', 44000.00, 10.00, 0.00, 12554.14, 'Online', 22000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (51, NULL, 53, 3, '2025-07-15', '2025-07-19', 'Checked-In', 40000.00, 10.00, 7358.12, 0.00, 'Cash', 16000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (60, NULL, 67, 3, '2025-08-21', '2025-08-24', 'Checked-In', 44000.00, 10.00, 5637.98, 0.00, 'Cash', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (57, NULL, 67, 3, '2025-08-08', '2025-08-11', 'Checked-Out', 47520.00, 10.00, 4810.47, 0.00, 'Cash', 14256.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (61, NULL, 40, 3, '2025-08-24', '2025-08-27', 'Checked-Out', 44000.00, 10.00, 8119.97, 0.00, 'BankTransfer', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (65, NULL, 29, 3, '2025-09-10', '2025-09-14', 'Checked-Out', 44000.00, 10.00, 8528.53, 0.00, 'Online', 17600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (8, NULL, 50, 1, '2025-08-03', '2025-08-08', 'Checked-Out', 44000.00, 10.00, 7091.78, 0.00, 'Card', 22000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (33, NULL, 137, 2, '2025-08-11', '2025-08-13', 'Checked-In', 44000.00, 10.00, 3703.85, 0.00, 'Online', 8800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (21, NULL, 75, 1, '2025-09-26', '2025-10-01', 'Cancelled', 47520.00, 10.00, 0.00, 0.00, 'Online', 23760.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (74, NULL, 110, 4, '2025-07-14', '2025-07-15', 'Cancelled', 24000.00, 10.00, 0.00, 0.00, 'BankTransfer', 2400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (79, NULL, 93, 4, '2025-07-30', '2025-08-02', 'Cancelled', 24000.00, 10.00, 0.00, 0.00, 'Cash', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (47, NULL, 33, 3, '2025-07-01', '2025-07-04', 'Cancelled', 40000.00, 10.00, 4198.19, 0.00, 'Cash', 12000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (72, NULL, 145, 4, '2025-07-10', '2025-07-12', 'Checked-Out', 24000.00, 10.00, 0.00, 3329.90, 'Cash', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (183, NULL, 140, 8, '2025-09-02', '2025-09-05', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Cash', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (184, NULL, 20, 8, '2025-09-06', '2025-09-07', 'Checked-Out', 28512.00, 10.00, 0.00, 0.00, 'Cash', 2851.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (82, NULL, 8, 4, '2025-08-12', '2025-08-15', 'Checked-Out', 26400.00, 10.00, 0.00, 5553.42, 'BankTransfer', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (7, NULL, 35, 1, '2025-07-31', '2025-08-03', 'Checked-Out', 40000.00, 10.00, 5312.72, 8562.21, 'Online', 12000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (84, NULL, 109, 4, '2025-08-20', '2025-08-23', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Online', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (87, NULL, 77, 4, '2025-08-31', '2025-09-02', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Cash', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (88, NULL, 17, 4, '2025-09-04', '2025-09-08', 'Checked-In', 26400.00, 10.00, 0.00, 0.00, 'Card', 10560.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (90, NULL, 102, 4, '2025-09-14', '2025-09-19', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Online', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (92, NULL, 97, 4, '2025-09-22', '2025-09-27', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Cash', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (93, NULL, 83, 4, '2025-09-28', '2025-09-29', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Card', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (94, NULL, 145, 5, '2025-07-01', '2025-07-03', 'Checked-Out', 24000.00, 10.00, 0.00, 0.00, 'Online', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (96, NULL, 117, 5, '2025-07-09', '2025-07-11', 'Checked-Out', 24000.00, 10.00, 0.00, 0.00, 'Online', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (97, NULL, 70, 5, '2025-07-13', '2025-07-18', 'Checked-In', 24000.00, 10.00, 0.00, 0.00, 'Cash', 12000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (101, NULL, 129, 5, '2025-07-25', '2025-07-29', 'Checked-Out', 25920.00, 10.00, 0.00, 0.00, 'Cash', 10368.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (102, NULL, 21, 5, '2025-07-30', '2025-08-03', 'Checked-Out', 24000.00, 10.00, 0.00, 0.00, 'Cash', 9600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (106, NULL, 38, 5, '2025-08-18', '2025-08-21', 'Checked-In', 26400.00, 10.00, 0.00, 0.00, 'Cash', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (107, NULL, 76, 5, '2025-08-21', '2025-08-24', 'Checked-In', 26400.00, 10.00, 0.00, 0.00, 'BankTransfer', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (108, NULL, 119, 5, '2025-08-26', '2025-08-31', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Cash', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (110, NULL, 21, 5, '2025-09-03', '2025-09-05', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Online', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (111, NULL, 73, 5, '2025-09-06', '2025-09-11', 'Checked-Out', 28512.00, 10.00, 0.00, 0.00, 'Online', 14256.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (112, NULL, 99, 5, '2025-09-11', '2025-09-12', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Card', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (114, NULL, 145, 5, '2025-09-18', '2025-09-23', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Online', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (116, NULL, 75, 5, '2025-09-27', '2025-10-01', 'Checked-Out', 28512.00, 10.00, 0.00, 0.00, 'BankTransfer', 11404.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (118, NULL, 108, 6, '2025-07-05', '2025-07-06', 'Checked-Out', 25920.00, 10.00, 0.00, 0.00, 'BankTransfer', 2592.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (119, NULL, 59, 6, '2025-07-07', '2025-07-10', 'Checked-Out', 24000.00, 10.00, 0.00, 0.00, 'Cash', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (120, NULL, 4, 6, '2025-07-10', '2025-07-13', 'Checked-Out', 24000.00, 10.00, 0.00, 0.00, 'BankTransfer', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (123, NULL, 37, 6, '2025-07-25', '2025-07-29', 'Checked-In', 25920.00, 10.00, 0.00, 0.00, 'Online', 10368.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (125, NULL, 133, 6, '2025-07-31', '2025-08-01', 'Checked-Out', 24000.00, 10.00, 0.00, 0.00, 'Online', 2400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (131, NULL, 93, 6, '2025-08-22', '2025-08-25', 'Checked-Out', 28512.00, 10.00, 0.00, 0.00, 'BankTransfer', 8553.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (132, NULL, 126, 6, '2025-08-25', '2025-08-28', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Cash', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (133, NULL, 44, 6, '2025-08-29', '2025-08-30', 'Checked-Out', 28512.00, 10.00, 0.00, 0.00, 'Online', 2851.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (137, NULL, 97, 6, '2025-09-10', '2025-09-12', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Cash', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (139, NULL, 76, 6, '2025-09-14', '2025-09-17', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Card', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (141, NULL, 140, 6, '2025-09-26', '2025-09-28', 'Checked-Out', 28512.00, 10.00, 0.00, 0.00, 'BankTransfer', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (143, NULL, 130, 6, '2025-09-30', '2025-10-04', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Online', 10560.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (144, NULL, 58, 7, '2025-07-01', '2025-07-04', 'Checked-Out', 24000.00, 10.00, 0.00, 0.00, 'Card', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (145, NULL, 10, 7, '2025-07-05', '2025-07-08', 'Checked-Out', 25920.00, 10.00, 0.00, 0.00, 'Online', 7776.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (146, NULL, 134, 7, '2025-07-09', '2025-07-13', 'Checked-Out', 24000.00, 10.00, 0.00, 0.00, 'BankTransfer', 9600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (147, NULL, 89, 7, '2025-07-14', '2025-07-17', 'Checked-Out', 24000.00, 10.00, 0.00, 0.00, 'Online', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (148, NULL, 62, 7, '2025-07-18', '2025-07-22', 'Checked-Out', 25920.00, 10.00, 0.00, 0.00, 'Online', 10368.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (149, NULL, 108, 7, '2025-07-23', '2025-07-28', 'Checked-Out', 24000.00, 10.00, 0.00, 0.00, 'BankTransfer', 12000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (153, NULL, 112, 7, '2025-08-11', '2025-08-12', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Card', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (155, NULL, 1, 7, '2025-08-13', '2025-08-15', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Online', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (157, NULL, 69, 7, '2025-08-20', '2025-08-23', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Online', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (158, NULL, 99, 7, '2025-08-23', '2025-08-26', 'Checked-Out', 28512.00, 10.00, 0.00, 0.00, 'Online', 8553.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (160, NULL, 100, 7, '2025-08-31', '2025-09-05', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Cash', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (161, NULL, 146, 7, '2025-09-06', '2025-09-10', 'Checked-Out', 28512.00, 10.00, 0.00, 0.00, 'Cash', 11404.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (162, NULL, 52, 7, '2025-09-11', '2025-09-16', 'Checked-In', 26400.00, 10.00, 0.00, 0.00, 'Online', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (151, NULL, 99, 7, '2025-08-04', '2025-08-05', 'Cancelled', 26400.00, 10.00, 0.00, 0.00, 'Online', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (117, NULL, 134, 6, '2025-07-01', '2025-07-03', 'Cancelled', 24000.00, 10.00, 3314.98, 0.00, 'Card', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (100, NULL, 92, 5, '2025-07-23', '2025-07-24', 'Checked-Out', 24000.00, 10.00, 0.00, 2755.56, 'Card', 2400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (134, NULL, 36, 6, '2025-08-30', '2025-09-02', 'Checked-Out', 28512.00, 10.00, 4520.06, 0.00, 'Online', 8553.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (109, NULL, 73, 5, '2025-08-31', '2025-09-03', 'Checked-In', 26400.00, 10.00, 0.00, 6184.66, 'Cash', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (140, NULL, 17, 6, '2025-09-19', '2025-09-24', 'Checked-In', 28512.00, 10.00, 5001.57, 0.00, 'Online', 14256.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (85, NULL, 104, 4, '2025-08-24', '2025-08-25', 'Checked-Out', 26400.00, 10.00, 2617.67, 0.00, 'Card', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (89, NULL, 139, 4, '2025-09-09', '2025-09-13', 'Checked-Out', 26400.00, 10.00, 3362.60, 0.00, 'Cash', 10560.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (98, NULL, 132, 5, '2025-07-19', '2025-07-20', 'Checked-Out', 25920.00, 10.00, 3343.50, 0.00, 'BankTransfer', 2592.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (99, NULL, 142, 5, '2025-07-21', '2025-07-22', 'Checked-In', 24000.00, 10.00, 4385.09, 0.00, 'Card', 2400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (142, NULL, 19, 6, '2025-09-29', '2025-09-30', 'Checked-Out', 26400.00, 10.00, 0.00, 7177.38, 'Card', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (105, NULL, 120, 5, '2025-08-16', '2025-08-18', 'Checked-Out', 28512.00, 10.00, 1902.87, 0.00, 'BankTransfer', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (122, NULL, 63, 6, '2025-07-18', '2025-07-23', 'Checked-Out', 25920.00, 10.00, 4408.32, 0.00, 'Card', 12960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (154, NULL, 102, 7, '2025-08-12', '2025-08-13', 'Checked-Out', 26400.00, 10.00, 2517.87, 0.00, 'Online', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (86, NULL, 81, 4, '2025-08-25', '2025-08-30', 'Checked-In', 26400.00, 10.00, 3242.87, 0.00, 'Card', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (103, NULL, 69, 5, '2025-08-04', '2025-08-09', 'Checked-Out', 26400.00, 10.00, 3242.87, 0.00, 'Online', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (113, NULL, 83, 5, '2025-09-13', '2025-09-16', 'Checked-Out', 28512.00, 10.00, 3502.30, 0.00, 'Online', 8553.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (265, NULL, 78, 12, '2025-07-12', '2025-07-14', 'Checked-Out', 19440.00, 10.00, 0.00, 0.00, 'Online', 3888.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (271, NULL, 54, 12, '2025-08-06', '2025-08-08', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Online', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (272, NULL, 49, 12, '2025-08-09', '2025-08-13', 'Checked-Out', 21384.00, 10.00, 0.00, 0.00, 'Cash', 8553.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (130, NULL, 55, 6, '2025-08-18', '2025-08-22', 'Checked-In', 26400.00, 10.00, 3242.87, 0.00, 'Online', 10560.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (159, NULL, 49, 7, '2025-08-26', '2025-08-30', 'Checked-Out', 26400.00, 10.00, 3242.87, 0.00, 'Cash', 10560.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (115, NULL, 101, 5, '2025-09-23', '2025-09-25', 'Checked-Out', 26400.00, 10.00, 3242.87, 0.00, 'Online', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (135, NULL, 11, 6, '2025-09-04', '2025-09-06', 'Checked-Out', 26400.00, 10.00, 1460.74, 6410.33, 'Cash', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (95, NULL, 122, 5, '2025-07-05', '2025-07-08', 'Checked-Out', 25920.00, 10.00, 3183.90, 5243.45, 'Cash', 7776.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (150, NULL, 98, 7, '2025-07-30', '2025-08-02', 'Checked-Out', 24000.00, 10.00, 2948.06, 6310.40, 'Online', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (166, NULL, 117, 7, '2025-09-30', '2025-10-04', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Cash', 10560.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (169, NULL, 58, 8, '2025-07-11', '2025-07-12', 'Checked-Out', 25920.00, 10.00, 0.00, 0.00, 'BankTransfer', 2592.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (170, NULL, 79, 8, '2025-07-14', '2025-07-17', 'Checked-Out', 24000.00, 10.00, 0.00, 0.00, 'Online', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (173, NULL, 30, 8, '2025-07-26', '2025-07-28', 'Checked-In', 25920.00, 10.00, 0.00, 0.00, 'Card', 5184.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (177, NULL, 23, 8, '2025-08-09', '2025-08-14', 'Checked-In', 28512.00, 10.00, 0.00, 0.00, 'Online', 14256.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (180, NULL, 27, 8, '2025-08-25', '2025-08-27', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'BankTransfer', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (182, NULL, 44, 8, '2025-08-30', '2025-09-01', 'Checked-In', 28512.00, 10.00, 0.00, 0.00, 'Online', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (186, NULL, 86, 8, '2025-09-14', '2025-09-16', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'BankTransfer', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (187, NULL, 108, 8, '2025-09-17', '2025-09-19', 'Checked-In', 26400.00, 10.00, 0.00, 0.00, 'Cash', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (188, NULL, 89, 8, '2025-09-21', '2025-09-26', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Cash', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (190, NULL, 32, 9, '2025-07-01', '2025-07-05', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Online', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (192, NULL, 116, 9, '2025-07-12', '2025-07-14', 'Checked-Out', 19440.00, 10.00, 0.00, 0.00, 'Cash', 3888.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (193, NULL, 108, 9, '2025-07-14', '2025-07-15', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Cash', 1800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (194, NULL, 147, 9, '2025-07-15', '2025-07-19', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Cash', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (196, NULL, 150, 9, '2025-07-26', '2025-07-27', 'Checked-Out', 19440.00, 10.00, 0.00, 0.00, 'Cash', 1944.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (197, NULL, 97, 9, '2025-07-28', '2025-07-31', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Cash', 5400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (199, NULL, 114, 9, '2025-08-06', '2025-08-11', 'Checked-In', 19800.00, 10.00, 0.00, 0.00, 'Cash', 9900.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (200, NULL, 46, 9, '2025-08-12', '2025-08-17', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Cash', 9900.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (202, NULL, 92, 9, '2025-08-21', '2025-08-26', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Cash', 9900.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (204, NULL, 67, 9, '2025-09-02', '2025-09-04', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Cash', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (205, NULL, 92, 9, '2025-09-04', '2025-09-09', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'BankTransfer', 9900.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (212, NULL, 55, 10, '2025-07-07', '2025-07-09', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Online', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (213, NULL, 120, 10, '2025-07-11', '2025-07-16', 'Checked-Out', 19440.00, 10.00, 0.00, 0.00, 'BankTransfer', 9720.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (214, NULL, 58, 10, '2025-07-16', '2025-07-17', 'Checked-In', 18000.00, 10.00, 0.00, 0.00, 'Cash', 1800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (216, NULL, 64, 10, '2025-07-23', '2025-07-25', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Card', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (221, NULL, 12, 10, '2025-08-07', '2025-08-10', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Card', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (224, NULL, 135, 10, '2025-08-17', '2025-08-20', 'Checked-In', 19800.00, 10.00, 0.00, 0.00, 'Cash', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (226, NULL, 2, 10, '2025-08-22', '2025-08-25', 'Checked-Out', 21384.00, 10.00, 0.00, 0.00, 'Online', 6415.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (229, NULL, 68, 10, '2025-08-31', '2025-09-03', 'Checked-In', 19800.00, 10.00, 0.00, 0.00, 'Card', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (230, NULL, 75, 10, '2025-09-04', '2025-09-06', 'Checked-In', 19800.00, 10.00, 0.00, 0.00, 'Cash', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (231, NULL, 24, 10, '2025-09-06', '2025-09-11', 'Checked-In', 21384.00, 10.00, 0.00, 0.00, 'Card', 10692.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (235, NULL, 24, 10, '2025-09-21', '2025-09-25', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Cash', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (236, NULL, 72, 10, '2025-09-25', '2025-09-28', 'Checked-In', 19800.00, 10.00, 0.00, 0.00, 'Online', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (240, NULL, 37, 11, '2025-07-09', '2025-07-11', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Cash', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (241, NULL, 92, 11, '2025-07-13', '2025-07-17', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Online', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (244, NULL, 43, 11, '2025-07-27', '2025-08-01', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'BankTransfer', 9000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (179, NULL, 146, 8, '2025-08-20', '2025-08-24', 'Checked-Out', 26400.00, 10.00, 4457.34, 0.00, 'Cash', 10560.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (207, NULL, 40, 9, '2025-09-10', '2025-09-14', 'Checked-In', 19800.00, 10.00, 2302.67, 0.00, 'Cash', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (167, NULL, 31, 8, '2025-07-01', '2025-07-04', 'Checked-Out', 24000.00, 10.00, 2948.06, 0.00, 'Online', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (222, NULL, 39, 10, '2025-08-11', '2025-08-13', 'Checked-Out', 19800.00, 10.00, 2016.23, 0.00, 'Online', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (168, NULL, 87, 8, '2025-07-05', '2025-07-09', 'Checked-Out', 25920.00, 10.00, 4412.13, 0.00, 'Online', 10368.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (171, NULL, 139, 8, '2025-07-18', '2025-07-22', 'Checked-Out', 25920.00, 10.00, 4210.10, 0.00, 'Online', 10368.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (201, NULL, 122, 9, '2025-08-18', '2025-08-20', 'Checked-Out', 19800.00, 10.00, 3354.36, 0.00, 'Online', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (208, NULL, 45, 9, '2025-09-16', '2025-09-19', 'Checked-Out', 19800.00, 10.00, 3900.09, 0.00, 'Cash', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (223, NULL, 141, 10, '2025-08-14', '2025-08-16', 'Checked-Out', 19800.00, 10.00, 1468.82, 0.00, 'Card', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (181, NULL, 78, 8, '2025-08-27', '2025-08-28', 'Cancelled', 26400.00, 10.00, 0.00, 0.00, 'Cash', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (174, NULL, 42, 8, '2025-07-28', '2025-07-30', 'Checked-Out', 24000.00, 10.00, 2948.06, 0.00, 'Online', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (178, NULL, 129, 8, '2025-08-16', '2025-08-19', 'Checked-Out', 28512.00, 10.00, 3502.30, 0.00, 'Card', 8553.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (191, NULL, 150, 9, '2025-07-06', '2025-07-10', 'Checked-Out', 18000.00, 10.00, 2211.05, 0.00, 'Cash', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (203, NULL, 29, 9, '2025-08-27', '2025-08-31', 'Checked-In', 19800.00, 10.00, 2432.15, 0.00, 'Online', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (227, NULL, 86, 10, '2025-08-25', '2025-08-27', 'Checked-Out', 19800.00, 10.00, 2432.15, 0.00, 'Card', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (242, NULL, 98, 11, '2025-07-19', '2025-07-23', 'Checked-Out', 19440.00, 10.00, 2387.93, 0.00, 'Cash', 7776.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (195, NULL, 40, 9, '2025-07-20', '2025-07-25', 'Cancelled', 18000.00, 10.00, 0.00, 0.00, 'BankTransfer', 9000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (211, NULL, 49, 10, '2025-07-01', '2025-07-06', 'Cancelled', 18000.00, 10.00, 0.00, 0.00, 'Online', 9000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (245, NULL, 12, 11, '2025-08-02', '2025-08-03', 'Cancelled', 21384.00, 10.00, 0.00, 0.00, 'Online', 2138.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (165, NULL, 60, 7, '2025-09-26', '2025-09-30', 'Checked-Out', 28512.00, 10.00, 0.00, 3833.98, 'Cash', 11404.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (350, NULL, 78, 15, '2025-09-23', '2025-09-24', 'Checked-In', 19800.00, 10.00, 0.00, 0.00, 'Cash', 1980.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (176, NULL, 52, 8, '2025-08-05', '2025-08-08', 'Checked-Out', 26400.00, 10.00, 0.00, 6486.33, 'Online', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (209, NULL, 120, 9, '2025-09-20', '2025-09-24', 'Checked-Out', 21384.00, 10.00, 0.00, 3511.61, 'Card', 8553.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (218, NULL, 47, 10, '2025-07-30', '2025-08-01', 'Checked-In', 18000.00, 10.00, 0.00, 4695.79, 'Cash', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (219, NULL, 21, 10, '2025-08-01', '2025-08-03', 'Checked-Out', 21384.00, 10.00, 0.00, 3751.19, 'Online', 4276.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (220, NULL, 64, 10, '2025-08-05', '2025-08-07', 'Checked-Out', 19800.00, 10.00, 0.00, 5101.29, 'Online', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (228, NULL, 36, 10, '2025-08-28', '2025-08-30', 'Checked-Out', 19800.00, 10.00, 0.00, 3799.20, 'Online', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (206, NULL, 42, 9, '2025-09-09', '2025-09-10', 'Checked-Out', 19800.00, 10.00, 1350.10, 5022.93, 'Online', 1980.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (215, NULL, 35, 10, '2025-07-19', '2025-07-22', 'Checked-Out', 19440.00, 10.00, 2920.71, 3409.81, 'Online', 5832.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (172, NULL, 140, 8, '2025-07-24', '2025-07-26', 'Checked-Out', 24000.00, 10.00, 2948.06, 7120.43, 'Cash', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (246, NULL, 96, 11, '2025-08-03', '2025-08-05', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Online', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (249, NULL, 7, 11, '2025-08-13', '2025-08-15', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Cash', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (251, NULL, 137, 11, '2025-08-18', '2025-08-21', 'Checked-In', 19800.00, 10.00, 0.00, 0.00, 'BankTransfer', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (252, NULL, 149, 11, '2025-08-21', '2025-08-25', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'BankTransfer', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (255, NULL, 95, 11, '2025-09-05', '2025-09-08', 'Checked-Out', 21384.00, 10.00, 0.00, 0.00, 'Cash', 6415.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (256, NULL, 87, 11, '2025-09-08', '2025-09-13', 'Checked-In', 19800.00, 10.00, 0.00, 0.00, 'Cash', 9900.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (259, NULL, 91, 11, '2025-09-22', '2025-09-25', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'BankTransfer', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (260, NULL, 76, 11, '2025-09-25', '2025-09-29', 'Checked-In', 19800.00, 10.00, 0.00, 0.00, 'Cash', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (262, NULL, 127, 12, '2025-07-01', '2025-07-03', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Card', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (263, NULL, 30, 12, '2025-07-04', '2025-07-09', 'Checked-Out', 19440.00, 10.00, 0.00, 0.00, 'Online', 9720.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (264, NULL, 29, 12, '2025-07-10', '2025-07-12', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Card', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (273, NULL, 1, 12, '2025-08-13', '2025-08-15', 'Checked-In', 19800.00, 10.00, 0.00, 0.00, 'Cash', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (274, NULL, 134, 12, '2025-08-15', '2025-08-19', 'Checked-Out', 21384.00, 10.00, 0.00, 0.00, 'Card', 8553.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (275, NULL, 69, 12, '2025-08-19', '2025-08-22', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Online', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (276, NULL, 121, 12, '2025-08-24', '2025-08-27', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Online', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (278, NULL, 148, 12, '2025-08-29', '2025-08-31', 'Checked-Out', 21384.00, 10.00, 0.00, 0.00, 'Online', 4276.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (279, NULL, 32, 12, '2025-08-31', '2025-09-05', 'Checked-In', 19800.00, 10.00, 0.00, 0.00, 'Online', 9900.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (280, NULL, 105, 12, '2025-09-05', '2025-09-09', 'Checked-Out', 21384.00, 10.00, 0.00, 0.00, 'Online', 8553.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (285, NULL, 27, 12, '2025-09-30', '2025-10-03', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Card', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (286, NULL, 31, 13, '2025-07-01', '2025-07-02', 'Checked-In', 18000.00, 10.00, 0.00, 0.00, 'Cash', 1800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (290, NULL, 131, 13, '2025-07-15', '2025-07-20', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Online', 9000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (291, NULL, 105, 13, '2025-07-21', '2025-07-25', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Card', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (295, NULL, 38, 13, '2025-08-10', '2025-08-15', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Card', 9900.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (296, NULL, 115, 13, '2025-08-16', '2025-08-19', 'Checked-Out', 21384.00, 10.00, 0.00, 0.00, 'Card', 6415.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (297, NULL, 6, 13, '2025-08-19', '2025-08-22', 'Checked-In', 19800.00, 10.00, 0.00, 0.00, 'Online', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (302, NULL, 36, 13, '2025-09-06', '2025-09-10', 'Checked-Out', 21384.00, 10.00, 0.00, 0.00, 'Card', 8553.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (303, NULL, 92, 13, '2025-09-10', '2025-09-14', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Cash', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (305, NULL, 88, 13, '2025-09-22', '2025-09-26', 'Checked-In', 19800.00, 10.00, 0.00, 0.00, 'Online', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (306, NULL, 132, 13, '2025-09-27', '2025-09-28', 'Checked-Out', 21384.00, 10.00, 0.00, 0.00, 'Online', 2138.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (308, NULL, 45, 14, '2025-07-01', '2025-07-06', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Cash', 9000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (309, NULL, 44, 14, '2025-07-07', '2025-07-11', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Online', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (311, NULL, 79, 14, '2025-07-16', '2025-07-20', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Cash', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (313, NULL, 34, 14, '2025-07-27', '2025-07-29', 'Checked-In', 18000.00, 10.00, 0.00, 0.00, 'Cash', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (315, NULL, 108, 14, '2025-08-06', '2025-08-10', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Online', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (317, NULL, 20, 14, '2025-08-13', '2025-08-17', 'Checked-In', 19800.00, 10.00, 0.00, 0.00, 'Cash', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (320, NULL, 20, 14, '2025-08-27', '2025-08-30', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Online', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (323, NULL, 69, 14, '2025-09-12', '2025-09-15', 'Checked-In', 21384.00, 10.00, 0.00, 0.00, 'BankTransfer', 6415.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (324, NULL, 141, 14, '2025-09-16', '2025-09-19', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'BankTransfer', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (247, NULL, 108, 11, '2025-08-06', '2025-08-10', 'Checked-Out', 19800.00, 10.00, 2348.40, 0.00, 'Card', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (258, NULL, 83, 11, '2025-09-19', '2025-09-22', 'Checked-Out', 21384.00, 10.00, 1854.52, 0.00, 'Online', 6415.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (283, NULL, 42, 12, '2025-09-19', '2025-09-24', 'Checked-Out', 21384.00, 10.00, 4011.40, 0.00, 'BankTransfer', 10692.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (299, NULL, 129, 13, '2025-08-28', '2025-08-29', 'Checked-Out', 19800.00, 10.00, 1437.64, 0.00, 'Card', 1980.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (319, NULL, 54, 14, '2025-08-24', '2025-08-27', 'Checked-In', 19800.00, 10.00, 2728.37, 0.00, 'Card', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (248, NULL, 57, 11, '2025-08-10', '2025-08-12', 'Checked-Out', 19800.00, 10.00, 2432.15, 0.00, 'Online', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (250, NULL, 4, 11, '2025-08-16', '2025-08-17', 'Checked-Out', 21384.00, 10.00, 2626.72, 0.00, 'BankTransfer', 2138.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (267, NULL, 50, 12, '2025-07-19', '2025-07-23', 'Checked-Out', 19440.00, 10.00, 2387.93, 0.00, 'Cash', 7776.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (269, NULL, 80, 12, '2025-07-29', '2025-08-01', 'Checked-Out', 18000.00, 10.00, 2211.05, 0.00, 'Cash', 5400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (277, NULL, 83, 12, '2025-08-27', '2025-08-29', 'Checked-Out', 19800.00, 10.00, 2432.15, 0.00, 'Cash', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (281, NULL, 56, 12, '2025-09-11', '2025-09-15', 'Checked-Out', 19800.00, 10.00, 2432.15, 0.00, 'Card', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (282, NULL, 147, 12, '2025-09-16', '2025-09-18', 'Checked-Out', 19800.00, 10.00, 2432.15, 0.00, 'Card', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (322, NULL, 36, 14, '2025-09-06', '2025-09-10', 'Checked-Out', 21384.00, 10.00, 2626.72, 0.00, 'BankTransfer', 8553.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (253, NULL, 107, 11, '2025-08-27', '2025-08-29', 'Cancelled', 19800.00, 10.00, 0.00, 0.00, 'Online', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (288, NULL, 82, 13, '2025-07-09', '2025-07-11', 'Cancelled', 18000.00, 10.00, 0.00, 0.00, 'BankTransfer', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (321, NULL, 42, 14, '2025-08-31', '2025-09-04', 'Cancelled', 19800.00, 10.00, 0.00, 0.00, 'BankTransfer', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (268, NULL, 10, 12, '2025-07-24', '2025-07-29', 'Checked-Out', 18000.00, 10.00, 0.00, 3651.80, 'Cash', 9000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (287, NULL, 150, 13, '2025-07-03', '2025-07-07', 'Checked-Out', 18000.00, 10.00, 0.00, 4331.16, 'Cash', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (430, NULL, 67, 19, '2025-07-24', '2025-07-27', 'Checked-Out', 12000.00, 10.00, 0.00, 0.00, 'BankTransfer', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (432, NULL, 107, 19, '2025-07-30', '2025-08-01', 'Checked-Out', 12000.00, 10.00, 0.00, 0.00, 'Cash', 2400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (433, NULL, 110, 19, '2025-08-01', '2025-08-05', 'Checked-Out', 14256.00, 10.00, 0.00, 0.00, 'Card', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (437, NULL, 56, 19, '2025-08-15', '2025-08-17', 'Checked-In', 14256.00, 10.00, 0.00, 0.00, 'Cash', 2851.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (289, NULL, 12, 13, '2025-07-13', '2025-07-14', 'Checked-In', 18000.00, 10.00, 0.00, 1838.02, 'Card', 1800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (292, NULL, 48, 13, '2025-07-25', '2025-07-30', 'Checked-Out', 19440.00, 10.00, 0.00, 4660.88, 'Online', 9720.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (307, NULL, 2, 13, '2025-09-30', '2025-10-03', 'Checked-In', 19800.00, 10.00, 0.00, 2460.96, 'Cash', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (310, NULL, 3, 14, '2025-07-11', '2025-07-15', 'Checked-Out', 19440.00, 10.00, 0.00, 2411.96, 'Cash', 7776.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (318, NULL, 13, 14, '2025-08-19', '2025-08-22', 'Checked-Out', 19800.00, 10.00, 0.00, 2846.71, 'BankTransfer', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (261, NULL, 90, 11, '2025-09-30', '2025-10-03', 'Checked-Out', 19800.00, 10.00, 2090.63, 2458.19, 'BankTransfer', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (266, NULL, 126, 12, '2025-07-14', '2025-07-17', 'Checked-Out', 18000.00, 10.00, 1457.14, 2295.35, 'BankTransfer', 5400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (257, NULL, 99, 11, '2025-09-14', '2025-09-17', 'Checked-Out', 19800.00, 10.00, 2432.15, 2976.88, 'Cash', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (328, NULL, 139, 15, '2025-07-01', '2025-07-03', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Online', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (329, NULL, 55, 15, '2025-07-04', '2025-07-08', 'Checked-Out', 19440.00, 10.00, 0.00, 0.00, 'Cash', 7776.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (331, NULL, 117, 15, '2025-07-13', '2025-07-18', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Online', 9000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (332, NULL, 137, 15, '2025-07-19', '2025-07-22', 'Checked-Out', 19440.00, 10.00, 0.00, 0.00, 'Cash', 5832.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (333, NULL, 135, 15, '2025-07-23', '2025-07-26', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Cash', 5400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (334, NULL, 118, 15, '2025-07-26', '2025-07-28', 'Checked-Out', 19440.00, 10.00, 0.00, 0.00, 'Card', 3888.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (335, NULL, 138, 15, '2025-07-30', '2025-07-31', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Cash', 1800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (336, NULL, 79, 15, '2025-08-02', '2025-08-06', 'Checked-Out', 21384.00, 10.00, 0.00, 0.00, 'Online', 8553.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (337, NULL, 68, 15, '2025-08-07', '2025-08-08', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Online', 1980.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (338, NULL, 54, 15, '2025-08-08', '2025-08-10', 'Checked-Out', 21384.00, 10.00, 0.00, 0.00, 'Online', 4276.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (340, NULL, 149, 15, '2025-08-13', '2025-08-15', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'BankTransfer', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (342, NULL, 53, 15, '2025-08-22', '2025-08-23', 'Checked-Out', 21384.00, 10.00, 0.00, 0.00, 'Cash', 2138.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (345, NULL, 6, 15, '2025-09-01', '2025-09-05', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Online', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (347, NULL, 81, 15, '2025-09-10', '2025-09-15', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Card', 9900.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (351, NULL, 79, 15, '2025-09-24', '2025-09-27', 'Checked-In', 19800.00, 10.00, 0.00, 0.00, 'Cash', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (352, NULL, 55, 15, '2025-09-27', '2025-09-29', 'Checked-Out', 21384.00, 10.00, 0.00, 0.00, 'BankTransfer', 4276.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (353, NULL, 108, 15, '2025-09-29', '2025-10-02', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Online', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (354, NULL, 147, 16, '2025-07-01', '2025-07-04', 'Checked-Out', 12000.00, 10.00, 0.00, 0.00, 'Online', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (355, NULL, 74, 16, '2025-07-05', '2025-07-08', 'Checked-Out', 12960.00, 10.00, 0.00, 0.00, 'Card', 3888.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (357, NULL, 55, 16, '2025-07-12', '2025-07-14', 'Checked-Out', 12960.00, 10.00, 0.00, 0.00, 'BankTransfer', 2592.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (358, NULL, 59, 16, '2025-07-15', '2025-07-18', 'Checked-Out', 12000.00, 10.00, 0.00, 0.00, 'Online', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (360, NULL, 92, 16, '2025-07-23', '2025-07-27', 'Checked-Out', 12000.00, 10.00, 0.00, 0.00, 'Card', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (363, NULL, 47, 16, '2025-08-04', '2025-08-06', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Cash', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (364, NULL, 32, 16, '2025-08-08', '2025-08-10', 'Checked-In', 14256.00, 10.00, 0.00, 0.00, 'Cash', 2851.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (367, NULL, 62, 16, '2025-08-17', '2025-08-19', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Card', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (369, NULL, 98, 16, '2025-08-26', '2025-08-31', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Cash', 6600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (371, NULL, 88, 16, '2025-09-05', '2025-09-07', 'Checked-Out', 14256.00, 10.00, 0.00, 0.00, 'Cash', 2851.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (372, NULL, 35, 16, '2025-09-08', '2025-09-10', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Card', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (373, NULL, 14, 16, '2025-09-12', '2025-09-14', 'Checked-Out', 14256.00, 10.00, 0.00, 0.00, 'BankTransfer', 2851.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (374, NULL, 123, 16, '2025-09-15', '2025-09-16', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Cash', 1320.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (375, NULL, 38, 16, '2025-09-18', '2025-09-21', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Cash', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (376, NULL, 11, 16, '2025-09-21', '2025-09-24', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Cash', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (378, NULL, 63, 16, '2025-09-28', '2025-10-02', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Online', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (380, NULL, 9, 17, '2025-07-04', '2025-07-05', 'Checked-Out', 12960.00, 10.00, 0.00, 0.00, 'Cash', 1296.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (381, NULL, 47, 17, '2025-07-05', '2025-07-10', 'Checked-Out', 12960.00, 10.00, 0.00, 0.00, 'Cash', 6480.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (384, NULL, 17, 17, '2025-07-19', '2025-07-24', 'Checked-Out', 12960.00, 10.00, 0.00, 0.00, 'Online', 6480.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (385, NULL, 129, 17, '2025-07-24', '2025-07-27', 'Checked-Out', 12000.00, 10.00, 0.00, 0.00, 'Online', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (387, NULL, 89, 17, '2025-07-31', '2025-08-05', 'Checked-In', 12000.00, 10.00, 0.00, 0.00, 'Card', 6000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (390, NULL, 144, 17, '2025-08-15', '2025-08-19', 'Checked-Out', 14256.00, 10.00, 0.00, 0.00, 'Cash', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (392, NULL, 14, 17, '2025-08-25', '2025-08-29', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Online', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (393, NULL, 69, 17, '2025-08-30', '2025-09-03', 'Checked-Out', 14256.00, 10.00, 0.00, 0.00, 'Cash', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (394, NULL, 126, 17, '2025-09-04', '2025-09-08', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Card', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (397, NULL, 36, 17, '2025-09-15', '2025-09-17', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Online', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (398, NULL, 55, 17, '2025-09-19', '2025-09-21', 'Checked-In', 14256.00, 10.00, 0.00, 0.00, 'BankTransfer', 2851.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (399, NULL, 118, 17, '2025-09-22', '2025-09-27', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Card', 6600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (400, NULL, 89, 17, '2025-09-27', '2025-10-01', 'Checked-Out', 14256.00, 10.00, 0.00, 0.00, 'Online', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (401, NULL, 68, 18, '2025-07-01', '2025-07-03', 'Checked-In', 12000.00, 10.00, 0.00, 0.00, 'Card', 2400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (402, NULL, 59, 18, '2025-07-05', '2025-07-07', 'Checked-In', 12960.00, 10.00, 0.00, 0.00, 'Online', 2592.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (403, NULL, 112, 18, '2025-07-09', '2025-07-10', 'Checked-Out', 12000.00, 10.00, 0.00, 0.00, 'Online', 1200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (407, NULL, 39, 18, '2025-07-25', '2025-07-29', 'Checked-In', 12960.00, 10.00, 0.00, 0.00, 'Online', 5184.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (349, NULL, 56, 15, '2025-09-18', '2025-09-21', 'Checked-Out', 19800.00, 10.00, 3836.12, 0.00, 'Cash', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (359, NULL, 9, 16, '2025-07-19', '2025-07-22', 'Checked-Out', 12960.00, 10.00, 1399.83, 0.00, 'Online', 3888.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (382, NULL, 67, 17, '2025-07-12', '2025-07-14', 'Checked-Out', 12960.00, 10.00, 2272.46, 0.00, 'Cash', 2592.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (362, NULL, 40, 16, '2025-07-31', '2025-08-03', 'Cancelled', 12000.00, 10.00, 0.00, 0.00, 'BankTransfer', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (379, NULL, 23, 17, '2025-07-01', '2025-07-03', 'Checked-In', 12000.00, 10.00, 1126.09, 0.00, 'BankTransfer', 2400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (386, NULL, 75, 17, '2025-07-27', '2025-07-30', 'Checked-Out', 12000.00, 10.00, 1557.65, 0.00, 'BankTransfer', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (404, NULL, 76, 18, '2025-07-10', '2025-07-12', 'Checked-Out', 12000.00, 10.00, 605.85, 0.00, 'BankTransfer', 2400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (341, NULL, 124, 15, '2025-08-17', '2025-08-21', 'Checked-Out', 19800.00, 10.00, 2432.15, 0.00, 'Online', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (343, NULL, 42, 15, '2025-08-24', '2025-08-26', 'Checked-Out', 19800.00, 10.00, 2432.15, 0.00, 'Online', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (344, NULL, 148, 15, '2025-08-28', '2025-08-30', 'Checked-In', 19800.00, 10.00, 0.00, 3555.34, 'Cash', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (388, NULL, 25, 17, '2025-08-07', '2025-08-11', 'Checked-Out', 13200.00, 10.00, 1621.43, 0.00, 'BankTransfer', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (391, NULL, 57, 17, '2025-08-19', '2025-08-23', 'Checked-Out', 13200.00, 10.00, 1621.43, 0.00, 'Online', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (330, NULL, 2, 15, '2025-07-09', '2025-07-13', 'Checked-In', 18000.00, 10.00, 2211.05, 0.00, 'Cash', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (389, NULL, 66, 17, '2025-08-11', '2025-08-14', 'Cancelled', 13200.00, 10.00, 0.00, 0.00, 'Cash', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (368, NULL, 34, 16, '2025-08-21', '2025-08-26', 'Cancelled', 13200.00, 10.00, 1621.43, 0.00, 'Online', 6600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (370, NULL, 127, 16, '2025-09-01', '2025-09-05', 'Checked-In', 13200.00, 10.00, 0.00, 2054.59, 'Cash', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (406, NULL, 139, 18, '2025-07-20', '2025-07-24', 'Checked-Out', 12000.00, 10.00, 0.00, 3362.99, 'BankTransfer', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (346, NULL, 59, 15, '2025-09-06', '2025-09-09', 'Checked-Out', 21384.00, 10.00, 1618.29, 5888.78, 'Online', 6415.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (395, NULL, 69, 17, '2025-09-09', '2025-09-12', 'Checked-In', 13200.00, 10.00, 1355.09, 2298.51, 'Card', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (356, NULL, 138, 16, '2025-07-08', '2025-07-12', 'Checked-Out', 12000.00, 10.00, 1474.03, 2022.86, 'Cash', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (409, NULL, 109, 18, '2025-08-03', '2025-08-06', 'Checked-In', 13200.00, 10.00, 0.00, 0.00, 'Card', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (411, NULL, 32, 18, '2025-08-11', '2025-08-15', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Card', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (412, NULL, 4, 18, '2025-08-16', '2025-08-20', 'Checked-Out', 14256.00, 10.00, 0.00, 0.00, 'BankTransfer', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (413, NULL, 80, 18, '2025-08-21', '2025-08-22', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Card', 1320.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (415, NULL, 21, 18, '2025-08-29', '2025-09-02', 'Checked-In', 14256.00, 10.00, 0.00, 0.00, 'BankTransfer', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (416, NULL, 87, 18, '2025-09-04', '2025-09-06', 'Checked-In', 13200.00, 10.00, 0.00, 0.00, 'BankTransfer', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (417, NULL, 141, 18, '2025-09-07', '2025-09-09', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Card', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (420, NULL, 145, 18, '2025-09-19', '2025-09-20', 'Checked-In', 14256.00, 10.00, 0.00, 0.00, 'Cash', 1425.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (421, NULL, 142, 18, '2025-09-20', '2025-09-25', 'Checked-Out', 14256.00, 10.00, 0.00, 0.00, 'BankTransfer', 7128.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (422, NULL, 32, 18, '2025-09-27', '2025-09-29', 'Checked-Out', 14256.00, 10.00, 0.00, 0.00, 'Cash', 2851.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (423, NULL, 48, 18, '2025-09-29', '2025-10-03', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Cash', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (424, NULL, 37, 19, '2025-07-01', '2025-07-03', 'Checked-Out', 12000.00, 10.00, 0.00, 0.00, 'Cash', 2400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (426, NULL, 26, 19, '2025-07-04', '2025-07-09', 'Checked-Out', 12960.00, 10.00, 0.00, 0.00, 'BankTransfer', 6480.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (427, NULL, 84, 19, '2025-07-10', '2025-07-13', 'Checked-Out', 12000.00, 10.00, 0.00, 0.00, 'Card', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (428, NULL, 145, 19, '2025-07-14', '2025-07-18', 'Checked-Out', 12000.00, 10.00, 0.00, 0.00, 'Cash', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (429, NULL, 134, 19, '2025-07-19', '2025-07-23', 'Checked-In', 12960.00, 10.00, 0.00, 0.00, 'Cash', 5184.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (441, NULL, 6, 19, '2025-08-27', '2025-08-29', 'Checked-In', 13200.00, 10.00, 0.00, 0.00, 'Cash', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (443, NULL, 47, 19, '2025-09-05', '2025-09-07', 'Checked-Out', 14256.00, 10.00, 0.00, 0.00, 'Online', 2851.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (445, NULL, 128, 19, '2025-09-12', '2025-09-16', 'Checked-Out', 14256.00, 10.00, 0.00, 0.00, 'Cash', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (447, NULL, 105, 19, '2025-09-21', '2025-09-22', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Online', 1320.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (453, NULL, 85, 20, '2025-07-12', '2025-07-14', 'Checked-Out', 12960.00, 10.00, 0.00, 0.00, 'BankTransfer', 2592.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (454, NULL, 105, 20, '2025-07-14', '2025-07-17', 'Checked-Out', 12000.00, 10.00, 0.00, 0.00, 'Cash', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (456, NULL, 28, 20, '2025-07-24', '2025-07-29', 'Checked-Out', 12000.00, 10.00, 0.00, 0.00, 'Cash', 6000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (457, NULL, 46, 20, '2025-07-30', '2025-08-04', 'Checked-In', 12000.00, 10.00, 0.00, 0.00, 'Card', 6000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (458, NULL, 58, 20, '2025-08-06', '2025-08-07', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Online', 1320.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (460, NULL, 89, 20, '2025-08-14', '2025-08-16', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Online', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (465, NULL, 75, 20, '2025-09-02', '2025-09-06', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Online', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (466, NULL, 85, 20, '2025-09-06', '2025-09-10', 'Checked-Out', 14256.00, 10.00, 0.00, 0.00, 'Online', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (467, NULL, 72, 20, '2025-09-12', '2025-09-14', 'Checked-Out', 14256.00, 10.00, 0.00, 0.00, 'Cash', 2851.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (468, NULL, 121, 20, '2025-09-16', '2025-09-17', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Cash', 1320.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (469, NULL, 15, 20, '2025-09-18', '2025-09-21', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Online', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (470, NULL, 111, 20, '2025-09-22', '2025-09-26', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Online', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (472, NULL, 116, 20, '2025-09-29', '2025-10-01', 'Checked-In', 13200.00, 10.00, 0.00, 0.00, 'Online', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (474, NULL, 32, 21, '2025-07-05', '2025-07-10', 'Checked-Out', 43200.00, 10.00, 0.00, 0.00, 'Card', 21600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (475, NULL, 114, 21, '2025-07-11', '2025-07-13', 'Checked-Out', 43200.00, 10.00, 0.00, 0.00, 'BankTransfer', 8640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (476, NULL, 42, 21, '2025-07-14', '2025-07-16', 'Checked-Out', 40000.00, 10.00, 0.00, 0.00, 'Card', 8000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (478, NULL, 68, 21, '2025-07-19', '2025-07-23', 'Checked-In', 43200.00, 10.00, 0.00, 0.00, 'Cash', 17280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (479, NULL, 63, 21, '2025-07-25', '2025-07-28', 'Checked-Out', 43200.00, 10.00, 0.00, 0.00, 'Card', 12960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (480, NULL, 119, 21, '2025-07-28', '2025-07-30', 'Checked-Out', 40000.00, 10.00, 0.00, 0.00, 'Online', 8000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (482, NULL, 94, 21, '2025-08-05', '2025-08-09', 'Checked-Out', 44000.00, 10.00, 0.00, 0.00, 'Cash', 17600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (483, NULL, 119, 21, '2025-08-11', '2025-08-15', 'Checked-Out', 44000.00, 10.00, 0.00, 0.00, 'BankTransfer', 17600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (485, NULL, 146, 21, '2025-08-23', '2025-08-28', 'Checked-Out', 47520.00, 10.00, 0.00, 0.00, 'BankTransfer', 23760.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (487, NULL, 150, 21, '2025-09-03', '2025-09-08', 'Checked-Out', 44000.00, 10.00, 0.00, 0.00, 'Cash', 22000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (434, NULL, 81, 19, '2025-08-07', '2025-08-09', 'Checked-Out', 13200.00, 10.00, 1754.27, 0.00, 'Cash', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (448, NULL, 113, 19, '2025-09-23', '2025-09-28', 'Checked-Out', 13200.00, 10.00, 1166.86, 0.00, 'Cash', 6600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (450, NULL, 3, 20, '2025-07-01', '2025-07-03', 'Checked-Out', 12000.00, 10.00, 1418.72, 0.00, 'Card', 2400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (451, NULL, 41, 20, '2025-07-04', '2025-07-07', 'Checked-Out', 12960.00, 10.00, 1515.03, 0.00, 'Card', 3888.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (414, NULL, 4, 18, '2025-08-23', '2025-08-28', 'Checked-Out', 14256.00, 10.00, 1190.87, 0.00, 'Cash', 7128.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (418, NULL, 128, 18, '2025-09-10', '2025-09-11', 'Checked-Out', 13200.00, 10.00, 1006.91, 0.00, 'Online', 1320.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (622, NULL, 53, 27, '2025-08-02', '2025-08-07', 'Checked-In', 28512.00, 10.00, 0.00, 0.00, 'Cash', 14256.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (625, NULL, 90, 27, '2025-08-18', '2025-08-20', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Online', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (425, NULL, 118, 19, '2025-07-03', '2025-07-04', 'Checked-Out', 12000.00, 10.00, 1651.87, 0.00, 'BankTransfer', 1200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (439, NULL, 22, 19, '2025-08-21', '2025-08-22', 'Checked-In', 13200.00, 10.00, 1943.48, 0.00, 'Card', 1320.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (440, NULL, 26, 19, '2025-08-23', '2025-08-27', 'Checked-Out', 14256.00, 10.00, 1972.69, 0.00, 'BankTransfer', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (410, NULL, 69, 18, '2025-08-06', '2025-08-09', 'Checked-Out', 13200.00, 10.00, 1621.43, 0.00, 'Card', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (446, NULL, 21, 19, '2025-09-18', '2025-09-20', 'Checked-In', 13200.00, 10.00, 1621.43, 0.00, 'Cash', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (449, NULL, 29, 19, '2025-09-29', '2025-10-01', 'Checked-Out', 13200.00, 10.00, 1621.43, 0.00, 'Online', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (455, NULL, 133, 20, '2025-07-18', '2025-07-23', 'Checked-Out', 12960.00, 10.00, 1591.95, 0.00, 'BankTransfer', 6480.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (461, NULL, 85, 20, '2025-08-18', '2025-08-20', 'Checked-In', 13200.00, 10.00, 1621.43, 0.00, 'Online', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (471, NULL, 45, 20, '2025-09-27', '2025-09-28', 'Checked-Out', 14256.00, 10.00, 1751.15, 0.00, 'Online', 1425.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (419, NULL, 85, 18, '2025-09-13', '2025-09-17', 'Checked-Out', 14256.00, 10.00, 0.00, 3278.21, 'Cash', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (408, NULL, 107, 18, '2025-07-30', '2025-08-02', 'Cancelled', 12000.00, 10.00, 0.00, 0.00, 'BankTransfer', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (444, NULL, 60, 19, '2025-09-07', '2025-09-11', 'Cancelled', 13200.00, 10.00, 0.00, 0.00, 'Card', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (473, NULL, 86, 21, '2025-07-01', '2025-07-04', 'Cancelled', 40000.00, 10.00, 0.00, 0.00, 'BankTransfer', 12000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (481, NULL, 73, 21, '2025-08-01', '2025-08-04', 'Cancelled', 47520.00, 10.00, 0.00, 0.00, 'Card', 14256.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (484, NULL, 103, 21, '2025-08-16', '2025-08-21', 'Cancelled', 47520.00, 10.00, 5837.16, 0.00, 'Cash', 23760.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (464, NULL, 87, 20, '2025-08-31', '2025-09-02', 'Checked-Out', 13200.00, 10.00, 0.00, 2468.98, 'Online', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (431, NULL, 13, 19, '2025-07-27', '2025-07-29', 'Checked-Out', 12000.00, 10.00, 1467.92, 1259.13, 'Card', 2400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (490, NULL, 140, 21, '2025-09-17', '2025-09-20', 'Checked-Out', 44000.00, 10.00, 0.00, 0.00, 'Cash', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (492, NULL, 64, 21, '2025-09-23', '2025-09-26', 'Checked-Out', 44000.00, 10.00, 0.00, 0.00, 'Online', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (496, NULL, 30, 22, '2025-07-10', '2025-07-15', 'Checked-In', 40000.00, 10.00, 0.00, 0.00, 'Online', 20000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (498, NULL, 47, 22, '2025-07-20', '2025-07-23', 'Checked-In', 40000.00, 10.00, 0.00, 0.00, 'Online', 12000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (499, NULL, 141, 22, '2025-07-23', '2025-07-26', 'Checked-In', 40000.00, 10.00, 0.00, 0.00, 'BankTransfer', 12000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (503, NULL, 100, 22, '2025-08-07', '2025-08-11', 'Checked-In', 44000.00, 10.00, 0.00, 0.00, 'Online', 17600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (504, NULL, 115, 22, '2025-08-12', '2025-08-15', 'Checked-Out', 44000.00, 10.00, 0.00, 0.00, 'Online', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (508, NULL, 143, 22, '2025-08-30', '2025-09-01', 'Checked-Out', 47520.00, 10.00, 0.00, 0.00, 'Online', 9504.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (509, NULL, 29, 22, '2025-09-01', '2025-09-04', 'Checked-Out', 44000.00, 10.00, 0.00, 0.00, 'Card', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (510, NULL, 16, 22, '2025-09-04', '2025-09-05', 'Checked-Out', 44000.00, 10.00, 0.00, 0.00, 'Online', 4400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (512, NULL, 139, 22, '2025-09-12', '2025-09-14', 'Checked-Out', 47520.00, 10.00, 0.00, 0.00, 'BankTransfer', 9504.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (513, NULL, 19, 22, '2025-09-14', '2025-09-19', 'Checked-In', 44000.00, 10.00, 0.00, 0.00, 'BankTransfer', 22000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (514, NULL, 12, 22, '2025-09-19', '2025-09-21', 'Checked-Out', 47520.00, 10.00, 0.00, 0.00, 'Online', 9504.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (516, NULL, 121, 22, '2025-09-26', '2025-09-28', 'Checked-Out', 47520.00, 10.00, 0.00, 0.00, 'BankTransfer', 9504.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (518, NULL, 57, 23, '2025-07-01', '2025-07-03', 'Checked-Out', 40000.00, 10.00, 0.00, 0.00, 'Online', 8000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (520, NULL, 106, 23, '2025-07-05', '2025-07-08', 'Checked-Out', 43200.00, 10.00, 0.00, 0.00, 'Cash', 12960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (523, NULL, 28, 23, '2025-07-17', '2025-07-21', 'Checked-Out', 40000.00, 10.00, 0.00, 0.00, 'Cash', 16000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (524, NULL, 62, 23, '2025-07-22', '2025-07-24', 'Checked-Out', 40000.00, 10.00, 0.00, 0.00, 'Cash', 8000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (526, NULL, 70, 23, '2025-07-26', '2025-07-31', 'Checked-Out', 43200.00, 10.00, 0.00, 0.00, 'Card', 21600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (528, NULL, 100, 23, '2025-08-08', '2025-08-11', 'Checked-Out', 47520.00, 10.00, 0.00, 0.00, 'BankTransfer', 14256.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (529, NULL, 129, 23, '2025-08-12', '2025-08-13', 'Checked-Out', 44000.00, 10.00, 0.00, 0.00, 'Cash', 4400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (530, NULL, 110, 23, '2025-08-15', '2025-08-18', 'Checked-Out', 47520.00, 10.00, 0.00, 0.00, 'BankTransfer', 14256.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (531, NULL, 33, 23, '2025-08-19', '2025-08-21', 'Checked-Out', 44000.00, 10.00, 0.00, 0.00, 'Online', 8800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (533, NULL, 103, 23, '2025-08-28', '2025-09-01', 'Checked-In', 44000.00, 10.00, 0.00, 0.00, 'BankTransfer', 17600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (534, NULL, 11, 23, '2025-09-02', '2025-09-05', 'Checked-In', 44000.00, 10.00, 0.00, 0.00, 'Cash', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (535, NULL, 35, 23, '2025-09-05', '2025-09-08', 'Checked-Out', 47520.00, 10.00, 0.00, 0.00, 'Online', 14256.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (538, NULL, 8, 23, '2025-09-16', '2025-09-17', 'Checked-Out', 44000.00, 10.00, 0.00, 0.00, 'Cash', 4400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (540, NULL, 60, 23, '2025-09-24', '2025-09-26', 'Checked-Out', 44000.00, 10.00, 0.00, 0.00, 'Cash', 8800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (543, NULL, 80, 24, '2025-07-01', '2025-07-04', 'Checked-Out', 24000.00, 10.00, 0.00, 0.00, 'Cash', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (544, NULL, 25, 24, '2025-07-05', '2025-07-06', 'Checked-Out', 25920.00, 10.00, 0.00, 0.00, 'Online', 2592.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (545, NULL, 74, 24, '2025-07-06', '2025-07-07', 'Checked-Out', 24000.00, 10.00, 0.00, 0.00, 'Cash', 2400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (546, NULL, 96, 24, '2025-07-08', '2025-07-12', 'Checked-Out', 24000.00, 10.00, 0.00, 0.00, 'Cash', 9600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (552, NULL, 116, 24, '2025-07-27', '2025-08-01', 'Checked-Out', 24000.00, 10.00, 0.00, 0.00, 'Online', 12000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (555, NULL, 139, 24, '2025-08-10', '2025-08-13', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Online', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (558, NULL, 148, 24, '2025-08-25', '2025-08-26', 'Checked-In', 26400.00, 10.00, 0.00, 0.00, 'Cash', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (562, NULL, 121, 24, '2025-09-06', '2025-09-10', 'Checked-Out', 28512.00, 10.00, 0.00, 0.00, 'Online', 11404.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (563, NULL, 120, 24, '2025-09-10', '2025-09-14', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Online', 10560.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (567, NULL, 69, 24, '2025-09-28', '2025-09-30', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'BankTransfer', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (568, NULL, 90, 25, '2025-07-01', '2025-07-06', 'Checked-In', 24000.00, 10.00, 0.00, 0.00, 'Online', 12000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (570, NULL, 96, 25, '2025-07-11', '2025-07-13', 'Checked-Out', 25920.00, 10.00, 0.00, 0.00, 'Online', 5184.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (502, NULL, 20, 22, '2025-08-02', '2025-08-06', 'Checked-Out', 47520.00, 10.00, 6958.18, 0.00, 'Cash', 19008.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (507, NULL, 20, 22, '2025-08-25', '2025-08-29', 'Checked-In', 44000.00, 10.00, 0.00, 9915.51, 'Cash', 17600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (515, NULL, 116, 22, '2025-09-23', '2025-09-25', 'Checked-Out', 44000.00, 10.00, 6667.32, 0.00, 'Online', 8800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (519, NULL, 146, 23, '2025-07-03', '2025-07-04', 'Checked-Out', 40000.00, 10.00, 4302.65, 0.00, 'Cash', 4000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (511, NULL, 67, 22, '2025-09-06', '2025-09-11', 'Cancelled', 47520.00, 10.00, 0.00, 0.00, 'Cash', 23760.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (525, NULL, 117, 23, '2025-07-24', '2025-07-26', 'Checked-Out', 40000.00, 10.00, 7172.06, 0.00, 'Card', 8000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (698, NULL, 28, 30, '2025-08-18', '2025-08-21', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Cash', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (532, NULL, 55, 23, '2025-08-22', '2025-08-26', 'Checked-Out', 47520.00, 10.00, 4316.53, 0.00, 'Cash', 19008.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (539, NULL, 36, 23, '2025-09-18', '2025-09-23', 'Checked-Out', 44000.00, 10.00, 5814.76, 0.00, 'Card', 22000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (521, NULL, 75, 23, '2025-07-09', '2025-07-14', 'Cancelled', 40000.00, 10.00, 0.00, 0.00, 'BankTransfer', 20000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (493, NULL, 57, 21, '2025-09-28', '2025-10-02', 'Checked-Out', 44000.00, 10.00, 6423.66, 0.00, 'Online', 17600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (537, NULL, 73, 23, '2025-09-10', '2025-09-15', 'Checked-Out', 44000.00, 10.00, 2223.52, 0.00, 'Cash', 22000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (542, NULL, 20, 23, '2025-09-29', '2025-10-04', 'Checked-In', 44000.00, 10.00, 2646.73, 0.00, 'Cash', 22000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (559, NULL, 10, 24, '2025-08-27', '2025-08-29', 'Cancelled', 26400.00, 10.00, 0.00, 0.00, 'Cash', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (556, NULL, 35, 24, '2025-08-14', '2025-08-17', 'Checked-In', 26400.00, 10.00, 4074.32, 0.00, 'Cash', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (566, NULL, 65, 24, '2025-09-24', '2025-09-26', 'Checked-In', 26400.00, 10.00, 2866.17, 0.00, 'Online', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (571, NULL, 40, 25, '2025-07-15', '2025-07-17', 'Checked-Out', 24000.00, 10.00, 2613.51, 0.00, 'Cash', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (491, NULL, 138, 21, '2025-09-21', '2025-09-23', 'Checked-Out', 44000.00, 10.00, 5404.78, 0.00, 'Online', 8800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (494, NULL, 105, 22, '2025-07-01', '2025-07-03', 'Checked-Out', 40000.00, 10.00, 4913.43, 0.00, 'Card', 8000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (500, NULL, 38, 22, '2025-07-27', '2025-07-28', 'Checked-Out', 40000.00, 10.00, 4913.43, 0.00, 'BankTransfer', 4000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (536, NULL, 88, 23, '2025-09-08', '2025-09-10', 'Checked-In', 44000.00, 10.00, 5404.78, 0.00, 'Online', 8800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (554, NULL, 27, 24, '2025-08-07', '2025-08-08', 'Checked-Out', 26400.00, 10.00, 3242.87, 0.00, 'Card', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (522, NULL, 92, 23, '2025-07-15', '2025-07-17', 'Checked-In', 40000.00, 10.00, 4913.43, 0.00, 'Cash', 8000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (541, NULL, 72, 23, '2025-09-27', '2025-09-29', 'Checked-In', 47520.00, 10.00, 5837.16, 0.00, 'Card', 9504.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (505, NULL, 24, 22, '2025-08-16', '2025-08-18', 'Cancelled', 47520.00, 10.00, 4232.48, 0.00, 'Online', 9504.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (569, NULL, 29, 25, '2025-07-07', '2025-07-10', 'Checked-Out', 24000.00, 10.00, 0.00, 7055.85, 'Cash', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (497, NULL, 32, 22, '2025-07-15', '2025-07-18', 'Checked-In', 40000.00, 10.00, 4114.57, 4555.00, 'Online', 12000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (557, NULL, 95, 24, '2025-08-19', '2025-08-23', 'Checked-Out', 26400.00, 10.00, 2722.90, 4818.01, 'Cash', 10560.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (573, NULL, 55, 25, '2025-07-22', '2025-07-24', 'Checked-In', 24000.00, 10.00, 0.00, 0.00, 'Online', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (576, NULL, 129, 25, '2025-08-04', '2025-08-08', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Cash', 10560.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (577, NULL, 149, 25, '2025-08-08', '2025-08-10', 'Checked-Out', 28512.00, 10.00, 0.00, 0.00, 'Cash', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (580, NULL, 47, 25, '2025-08-19', '2025-08-22', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Cash', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (582, NULL, 70, 25, '2025-08-30', '2025-09-01', 'Checked-Out', 28512.00, 10.00, 0.00, 0.00, 'Cash', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (583, NULL, 24, 25, '2025-09-02', '2025-09-04', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'BankTransfer', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (589, NULL, 108, 25, '2025-09-22', '2025-09-26', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Card', 10560.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (590, NULL, 18, 25, '2025-09-26', '2025-09-28', 'Checked-Out', 28512.00, 10.00, 0.00, 0.00, 'Cash', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (594, NULL, 79, 26, '2025-07-11', '2025-07-15', 'Checked-Out', 25920.00, 10.00, 0.00, 0.00, 'Card', 10368.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (596, NULL, 17, 26, '2025-07-23', '2025-07-26', 'Checked-Out', 24000.00, 10.00, 0.00, 0.00, 'Online', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (597, NULL, 145, 26, '2025-07-28', '2025-07-31', 'Checked-Out', 24000.00, 10.00, 0.00, 0.00, 'Online', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (599, NULL, 119, 26, '2025-08-06', '2025-08-08', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Cash', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (600, NULL, 44, 26, '2025-08-09', '2025-08-13', 'Checked-Out', 28512.00, 10.00, 0.00, 0.00, 'Online', 11404.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (601, NULL, 120, 26, '2025-08-14', '2025-08-18', 'Checked-In', 26400.00, 10.00, 0.00, 0.00, 'Online', 10560.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (602, NULL, 31, 26, '2025-08-19', '2025-08-24', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Online', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (608, NULL, 94, 26, '2025-09-13', '2025-09-15', 'Checked-Out', 28512.00, 10.00, 0.00, 0.00, 'Card', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (611, NULL, 10, 26, '2025-09-23', '2025-09-24', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Cash', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (612, NULL, 71, 26, '2025-09-26', '2025-09-29', 'Checked-In', 28512.00, 10.00, 0.00, 0.00, 'Cash', 8553.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (613, NULL, 137, 26, '2025-09-30', '2025-10-02', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Online', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (614, NULL, 105, 27, '2025-07-01', '2025-07-06', 'Checked-Out', 24000.00, 10.00, 0.00, 0.00, 'BankTransfer', 12000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (617, NULL, 53, 27, '2025-07-18', '2025-07-21', 'Checked-Out', 25920.00, 10.00, 0.00, 0.00, 'BankTransfer', 7776.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (618, NULL, 149, 27, '2025-07-21', '2025-07-23', 'Checked-Out', 24000.00, 10.00, 0.00, 0.00, 'Cash', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (621, NULL, 4, 27, '2025-07-30', '2025-08-02', 'Checked-Out', 24000.00, 10.00, 0.00, 0.00, 'BankTransfer', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (626, NULL, 57, 27, '2025-08-21', '2025-08-22', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Cash', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (627, NULL, 6, 27, '2025-08-22', '2025-08-25', 'Checked-Out', 28512.00, 10.00, 0.00, 0.00, 'Cash', 8553.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (628, NULL, 94, 27, '2025-08-26', '2025-08-28', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Online', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (630, NULL, 137, 27, '2025-09-04', '2025-09-08', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'BankTransfer', 10560.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (631, NULL, 53, 27, '2025-09-09', '2025-09-11', 'Checked-In', 26400.00, 10.00, 0.00, 0.00, 'Online', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (632, NULL, 102, 27, '2025-09-11', '2025-09-15', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Online', 10560.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (633, NULL, 24, 27, '2025-09-16', '2025-09-19', 'Checked-In', 26400.00, 10.00, 0.00, 0.00, 'Cash', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (636, NULL, 106, 27, '2025-09-30', '2025-10-05', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Online', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (637, NULL, 49, 28, '2025-07-01', '2025-07-04', 'Checked-Out', 24000.00, 10.00, 0.00, 0.00, 'BankTransfer', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (638, NULL, 144, 28, '2025-07-04', '2025-07-07', 'Checked-Out', 25920.00, 10.00, 0.00, 0.00, 'Online', 7776.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (639, NULL, 75, 28, '2025-07-08', '2025-07-12', 'Checked-Out', 24000.00, 10.00, 0.00, 0.00, 'Online', 9600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (640, NULL, 57, 28, '2025-07-13', '2025-07-17', 'Checked-Out', 24000.00, 10.00, 0.00, 0.00, 'Card', 9600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (641, NULL, 143, 28, '2025-07-17', '2025-07-21', 'Checked-Out', 24000.00, 10.00, 0.00, 0.00, 'Cash', 9600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (643, NULL, 1, 28, '2025-07-28', '2025-07-30', 'Checked-Out', 24000.00, 10.00, 0.00, 0.00, 'Card', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (645, NULL, 64, 28, '2025-08-03', '2025-08-05', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Cash', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (646, NULL, 135, 28, '2025-08-06', '2025-08-07', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Online', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (647, NULL, 121, 28, '2025-08-08', '2025-08-09', 'Checked-In', 28512.00, 10.00, 0.00, 0.00, 'Cash', 2851.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (648, NULL, 69, 28, '2025-08-10', '2025-08-12', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Online', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (649, NULL, 46, 28, '2025-08-13', '2025-08-17', 'Checked-In', 26400.00, 10.00, 0.00, 0.00, 'Cash', 10560.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (651, NULL, 73, 28, '2025-08-20', '2025-08-22', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'BankTransfer', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (572, NULL, 29, 25, '2025-07-18', '2025-07-20', 'Checked-Out', 25920.00, 10.00, 2042.84, 0.00, 'BankTransfer', 5184.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1440, NULL, 1, 2, '2025-11-10', '2025-11-12', 'Booked', 20000.00, 10.00, 0.00, 0.00, NULL, 5000.00, DEFAULT, '2025-10-07 11:32:12.262156+05:30');
INSERT INTO public.booking VALUES (790, NULL, 99, 34, '2025-08-17', '2025-08-20', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Cash', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (584, NULL, 1, 25, '2025-09-05', '2025-09-09', 'Checked-Out', 28512.00, 10.00, 4633.92, 0.00, 'Online', 11404.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (588, NULL, 51, 25, '2025-09-20', '2025-09-22', 'Cancelled', 28512.00, 10.00, 0.00, 0.00, 'Cash', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (591, NULL, 55, 25, '2025-09-29', '2025-10-04', 'Checked-In', 26400.00, 10.00, 3021.09, 0.00, 'Card', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (652, NULL, 55, 28, '2025-08-23', '2025-08-25', 'Checked-Out', 28512.00, 10.00, 4613.61, 0.00, 'Card', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (579, NULL, 25, 25, '2025-08-14', '2025-08-17', 'Checked-Out', 26400.00, 10.00, 5238.78, 0.00, 'BankTransfer', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (581, NULL, 79, 25, '2025-08-24', '2025-08-29', 'Checked-In', 26400.00, 10.00, 4887.95, 0.00, 'Card', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (586, NULL, 59, 25, '2025-09-16', '2025-09-17', 'Checked-Out', 26400.00, 10.00, 4843.63, 0.00, 'BankTransfer', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (624, NULL, 105, 27, '2025-08-14', '2025-08-17', 'Cancelled', 26400.00, 10.00, 3123.24, 0.00, 'Cash', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (603, NULL, 71, 26, '2025-08-25', '2025-08-29', 'Checked-Out', 26400.00, 10.00, 5026.53, 0.00, 'Card', 10560.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (609, NULL, 122, 26, '2025-09-16', '2025-09-19', 'Checked-In', 26400.00, 10.00, 2931.04, 0.00, 'BankTransfer', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (607, NULL, 7, 26, '2025-09-09', '2025-09-12', 'Checked-Out', 26400.00, 10.00, 3242.87, 0.00, 'Cash', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (629, NULL, 88, 27, '2025-08-29', '2025-09-03', 'Checked-Out', 28512.00, 10.00, 3502.30, 0.00, 'Card', 14256.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (634, NULL, 58, 27, '2025-09-20', '2025-09-24', 'Checked-Out', 28512.00, 10.00, 3502.30, 0.00, 'Card', 11404.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (585, NULL, 100, 25, '2025-09-10', '2025-09-15', 'Checked-Out', 26400.00, 10.00, 3242.87, 0.00, 'BankTransfer', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (592, NULL, 106, 26, '2025-07-01', '2025-07-04', 'Checked-Out', 24000.00, 10.00, 2948.06, 0.00, 'Cash', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (578, NULL, 13, 25, '2025-08-11', '2025-08-13', 'Checked-Out', 26400.00, 10.00, 0.00, 7707.81, 'Card', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (610, NULL, 90, 26, '2025-09-20', '2025-09-21', 'Checked-Out', 28512.00, 10.00, 0.00, 6599.82, 'Cash', 2851.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (616, NULL, 40, 27, '2025-07-12', '2025-07-17', 'Checked-Out', 25920.00, 10.00, 0.00, 2697.51, 'Online', 12960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (642, NULL, 39, 28, '2025-07-23', '2025-07-26', 'Checked-Out', 24000.00, 10.00, 0.00, 2950.24, 'Cash', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (650, NULL, 104, 28, '2025-08-17', '2025-08-20', 'Checked-In', 26400.00, 10.00, 0.00, 5873.29, 'Online', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (575, NULL, 119, 25, '2025-07-30', '2025-08-02', 'Checked-Out', 24000.00, 10.00, 3786.35, 3228.74, 'Card', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (598, NULL, 14, 26, '2025-08-01', '2025-08-05', 'Checked-In', 28512.00, 10.00, 3502.30, 6512.34, 'Card', 11404.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (653, NULL, 17, 28, '2025-08-26', '2025-08-29', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Cash', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (656, NULL, 5, 28, '2025-09-06', '2025-09-09', 'Checked-Out', 28512.00, 10.00, 0.00, 0.00, 'Cash', 8553.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (657, NULL, 3, 28, '2025-09-10', '2025-09-13', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'BankTransfer', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (659, NULL, 136, 28, '2025-09-21', '2025-09-24', 'Checked-In', 26400.00, 10.00, 0.00, 0.00, 'Cash', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (660, NULL, 33, 28, '2025-09-25', '2025-09-28', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Online', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (661, NULL, 130, 28, '2025-09-30', '2025-10-05', 'Checked-In', 26400.00, 10.00, 0.00, 0.00, 'Cash', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (663, NULL, 4, 29, '2025-07-03', '2025-07-05', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Card', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (664, NULL, 131, 29, '2025-07-06', '2025-07-09', 'Checked-In', 18000.00, 10.00, 0.00, 0.00, 'Cash', 5400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (665, NULL, 133, 29, '2025-07-11', '2025-07-14', 'Checked-Out', 19440.00, 10.00, 0.00, 0.00, 'Online', 5832.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (668, NULL, 66, 29, '2025-07-24', '2025-07-26', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Cash', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (669, NULL, 35, 29, '2025-07-27', '2025-07-28', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Cash', 1800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (670, NULL, 117, 29, '2025-07-29', '2025-07-30', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Card', 1800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (671, NULL, 82, 29, '2025-08-01', '2025-08-04', 'Checked-Out', 21384.00, 10.00, 0.00, 0.00, 'Online', 6415.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (672, NULL, 56, 29, '2025-08-04', '2025-08-05', 'Checked-In', 19800.00, 10.00, 0.00, 0.00, 'Cash', 1980.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (676, NULL, 27, 29, '2025-08-21', '2025-08-24', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Card', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (677, NULL, 128, 29, '2025-08-25', '2025-08-30', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Card', 9900.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (678, NULL, 62, 29, '2025-08-31', '2025-09-03', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'BankTransfer', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (680, NULL, 96, 29, '2025-09-06', '2025-09-10', 'Checked-Out', 21384.00, 10.00, 0.00, 0.00, 'Online', 8553.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (681, NULL, 35, 29, '2025-09-11', '2025-09-14', 'Checked-In', 19800.00, 10.00, 0.00, 0.00, 'Online', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (686, NULL, 4, 30, '2025-07-01', '2025-07-03', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Cash', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (689, NULL, 135, 30, '2025-07-10', '2025-07-15', 'Checked-In', 18000.00, 10.00, 0.00, 0.00, 'Cash', 9000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (690, NULL, 37, 30, '2025-07-15', '2025-07-16', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Online', 1800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (694, NULL, 128, 30, '2025-07-29', '2025-08-03', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Cash', 9000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (695, NULL, 110, 30, '2025-08-04', '2025-08-09', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Online', 9900.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (696, NULL, 88, 30, '2025-08-11', '2025-08-15', 'Checked-In', 19800.00, 10.00, 0.00, 0.00, 'Card', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (697, NULL, 122, 30, '2025-08-15', '2025-08-18', 'Checked-Out', 21384.00, 10.00, 0.00, 0.00, 'Card', 6415.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (699, NULL, 112, 30, '2025-08-22', '2025-08-24', 'Checked-Out', 21384.00, 10.00, 0.00, 0.00, 'Cash', 4276.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (700, NULL, 34, 30, '2025-08-24', '2025-08-29', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'BankTransfer', 9900.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (701, NULL, 92, 30, '2025-08-30', '2025-09-04', 'Checked-In', 21384.00, 10.00, 0.00, 0.00, 'Online', 10692.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (702, NULL, 85, 30, '2025-09-04', '2025-09-06', 'Checked-In', 19800.00, 10.00, 0.00, 0.00, 'Card', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (703, NULL, 6, 30, '2025-09-08', '2025-09-11', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Online', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (704, NULL, 92, 30, '2025-09-12', '2025-09-16', 'Checked-Out', 21384.00, 10.00, 0.00, 0.00, 'Card', 8553.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (705, NULL, 60, 30, '2025-09-17', '2025-09-20', 'Checked-In', 19800.00, 10.00, 0.00, 0.00, 'Card', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (706, NULL, 92, 30, '2025-09-21', '2025-09-26', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Online', 9900.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (707, NULL, 113, 30, '2025-09-27', '2025-10-02', 'Checked-Out', 21384.00, 10.00, 0.00, 0.00, 'Cash', 10692.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (708, NULL, 32, 31, '2025-07-01', '2025-07-03', 'Checked-In', 18000.00, 10.00, 0.00, 0.00, 'Online', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (709, NULL, 137, 31, '2025-07-04', '2025-07-06', 'Checked-In', 19440.00, 10.00, 0.00, 0.00, 'Card', 3888.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (710, NULL, 21, 31, '2025-07-08', '2025-07-13', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Online', 9000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (711, NULL, 127, 31, '2025-07-14', '2025-07-19', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Online', 9000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (713, NULL, 5, 31, '2025-07-27', '2025-07-31', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'BankTransfer', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (714, NULL, 134, 31, '2025-07-31', '2025-08-04', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Cash', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (715, NULL, 1, 31, '2025-08-05', '2025-08-08', 'Checked-In', 19800.00, 10.00, 0.00, 0.00, 'Online', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (716, NULL, 41, 31, '2025-08-08', '2025-08-09', 'Checked-Out', 21384.00, 10.00, 0.00, 0.00, 'Online', 2138.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1441, NULL, 1, 1, '2025-11-12', '2025-11-14', 'Checked-In', 20000.00, 10.00, 0.00, 0.00, NULL, 4000.00, DEFAULT, '2025-10-07 11:33:02.276951+05:30');
INSERT INTO public.booking VALUES (720, NULL, 51, 31, '2025-08-26', '2025-08-30', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Online', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (721, NULL, 135, 31, '2025-08-31', '2025-09-04', 'Checked-In', 19800.00, 10.00, 0.00, 0.00, 'Online', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (723, NULL, 15, 31, '2025-09-10', '2025-09-14', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'BankTransfer', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (724, NULL, 61, 31, '2025-09-15', '2025-09-18', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Online', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (728, NULL, 33, 32, '2025-07-03', '2025-07-07', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Cash', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (731, NULL, 126, 32, '2025-07-14', '2025-07-17', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'BankTransfer', 5400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (655, NULL, 97, 28, '2025-09-03', '2025-09-05', 'Checked-Out', 26400.00, 10.00, 2339.83, 0.00, 'BankTransfer', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (662, NULL, 120, 29, '2025-07-01', '2025-07-03', 'Checked-In', 18000.00, 10.00, 0.00, 3285.05, 'BankTransfer', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (692, NULL, 43, 30, '2025-07-22', '2025-07-26', 'Checked-Out', 18000.00, 10.00, 2476.42, 0.00, 'Cash', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (727, NULL, 77, 32, '2025-07-01', '2025-07-03', 'Checked-Out', 18000.00, 10.00, 1257.41, 0.00, 'Cash', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (729, NULL, 57, 32, '2025-07-08', '2025-07-13', 'Checked-In', 18000.00, 10.00, 1240.56, 0.00, 'Online', 9000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (667, NULL, 37, 29, '2025-07-20', '2025-07-24', 'Checked-Out', 18000.00, 10.00, 1526.95, 0.00, 'Card', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (673, NULL, 6, 29, '2025-08-07', '2025-08-11', 'Checked-Out', 19800.00, 10.00, 1684.37, 0.00, 'Card', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (674, NULL, 69, 29, '2025-08-13', '2025-08-15', 'Checked-In', 19800.00, 10.00, 1044.10, 0.00, 'BankTransfer', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (682, NULL, 22, 29, '2025-09-16', '2025-09-21', 'Checked-Out', 19800.00, 10.00, 3328.61, 0.00, 'Cash', 9900.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (683, NULL, 110, 29, '2025-09-22', '2025-09-25', 'Checked-Out', 19800.00, 10.00, 2414.23, 0.00, 'Cash', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (691, NULL, 7, 30, '2025-07-17', '2025-07-21', 'Checked-Out', 18000.00, 10.00, 0.00, 4780.25, 'Online', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (712, NULL, 105, 31, '2025-07-21', '2025-07-25', 'Cancelled', 18000.00, 10.00, 0.00, 0.00, 'Cash', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (684, NULL, 137, 29, '2025-09-26', '2025-09-28', 'Checked-Out', 21384.00, 10.00, 2626.72, 0.00, 'Online', 4276.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (719, NULL, 42, 31, '2025-08-21', '2025-08-25', 'Checked-Out', 19800.00, 10.00, 2432.15, 0.00, 'Card', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (718, NULL, 130, 31, '2025-08-16', '2025-08-19', 'Checked-In', 21384.00, 10.00, 2626.72, 0.00, 'BankTransfer', 6415.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (654, NULL, 78, 28, '2025-08-30', '2025-09-03', 'Cancelled', 28512.00, 10.00, 3502.30, 0.00, 'Online', 11404.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (688, NULL, 145, 30, '2025-07-05', '2025-07-09', 'Cancelled', 19440.00, 10.00, 3181.80, 0.00, 'Cash', 7776.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (722, NULL, 3, 31, '2025-09-05', '2025-09-09', 'Checked-Out', 21384.00, 10.00, 0.00, 4114.39, 'Card', 8553.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (658, NULL, 141, 28, '2025-09-14', '2025-09-19', 'Checked-Out', 26400.00, 10.00, 4454.77, 2970.90, 'BankTransfer', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (693, NULL, 36, 30, '2025-07-27', '2025-07-29', 'Checked-Out', 18000.00, 10.00, 1940.53, 5191.06, 'Cash', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (737, NULL, 123, 32, '2025-08-07', '2025-08-08', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Cash', 1980.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (738, NULL, 61, 32, '2025-08-09', '2025-08-10', 'Checked-In', 21384.00, 10.00, 0.00, 0.00, 'Online', 2138.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (739, NULL, 138, 32, '2025-08-10', '2025-08-14', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Online', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (743, NULL, 128, 32, '2025-08-28', '2025-08-29', 'Checked-In', 19800.00, 10.00, 0.00, 0.00, 'Online', 1980.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (744, NULL, 60, 32, '2025-08-31', '2025-09-04', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'BankTransfer', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (745, NULL, 6, 32, '2025-09-04', '2025-09-07', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Card', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (748, NULL, 75, 32, '2025-09-16', '2025-09-20', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'BankTransfer', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (750, NULL, 89, 32, '2025-09-25', '2025-09-30', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Online', 9900.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (753, NULL, 40, 33, '2025-07-06', '2025-07-11', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Card', 9000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (755, NULL, 45, 33, '2025-07-18', '2025-07-22', 'Checked-Out', 19440.00, 10.00, 0.00, 0.00, 'Online', 7776.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (756, NULL, 110, 33, '2025-07-24', '2025-07-29', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'BankTransfer', 9000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (757, NULL, 137, 33, '2025-07-30', '2025-08-03', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Cash', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (759, NULL, 38, 33, '2025-08-08', '2025-08-13', 'Checked-Out', 21384.00, 10.00, 0.00, 0.00, 'Online', 10692.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (760, NULL, 105, 33, '2025-08-14', '2025-08-17', 'Checked-In', 19800.00, 10.00, 0.00, 0.00, 'Cash', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (761, NULL, 24, 33, '2025-08-19', '2025-08-23', 'Checked-In', 19800.00, 10.00, 0.00, 0.00, 'BankTransfer', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (762, NULL, 124, 33, '2025-08-25', '2025-08-28', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Cash', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (769, NULL, 20, 33, '2025-09-17', '2025-09-20', 'Checked-In', 19800.00, 10.00, 0.00, 0.00, 'Online', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (771, NULL, 122, 33, '2025-09-27', '2025-09-29', 'Checked-Out', 21384.00, 10.00, 0.00, 0.00, 'Cash', 4276.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (773, NULL, 129, 34, '2025-07-01', '2025-07-04', 'Checked-In', 18000.00, 10.00, 0.00, 0.00, 'Online', 5400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (774, NULL, 21, 34, '2025-07-04', '2025-07-05', 'Checked-Out', 19440.00, 10.00, 0.00, 0.00, 'Cash', 1944.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (775, NULL, 13, 34, '2025-07-06', '2025-07-09', 'Checked-In', 18000.00, 10.00, 0.00, 0.00, 'Cash', 5400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (778, NULL, 126, 34, '2025-07-13', '2025-07-14', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Online', 1800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (780, NULL, 136, 34, '2025-07-16', '2025-07-18', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Online', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (781, NULL, 68, 34, '2025-07-18', '2025-07-22', 'Checked-Out', 19440.00, 10.00, 0.00, 0.00, 'Card', 7776.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (782, NULL, 2, 34, '2025-07-22', '2025-07-26', 'Checked-In', 18000.00, 10.00, 0.00, 0.00, 'BankTransfer', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (784, NULL, 15, 34, '2025-08-02', '2025-08-04', 'Checked-Out', 21384.00, 10.00, 0.00, 0.00, 'Cash', 4276.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (786, NULL, 101, 34, '2025-08-06', '2025-08-09', 'Checked-In', 19800.00, 10.00, 0.00, 0.00, 'Cash', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (787, NULL, 104, 34, '2025-08-09', '2025-08-10', 'Checked-Out', 21384.00, 10.00, 0.00, 0.00, 'Card', 2138.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (789, NULL, 60, 34, '2025-08-15', '2025-08-17', 'Checked-In', 21384.00, 10.00, 0.00, 0.00, 'Card', 4276.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (792, NULL, 90, 34, '2025-08-24', '2025-08-29', 'Checked-In', 19800.00, 10.00, 0.00, 0.00, 'BankTransfer', 9900.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (793, NULL, 46, 34, '2025-08-31', '2025-09-05', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Online', 9900.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (794, NULL, 15, 34, '2025-09-06', '2025-09-09', 'Checked-Out', 21384.00, 10.00, 0.00, 0.00, 'Online', 6415.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (795, NULL, 29, 34, '2025-09-10', '2025-09-11', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Online', 1980.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (797, NULL, 13, 34, '2025-09-16', '2025-09-21', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Cash', 9900.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (798, NULL, 72, 34, '2025-09-22', '2025-09-25', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Cash', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (800, NULL, 41, 34, '2025-09-29', '2025-10-03', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Online', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (801, NULL, 30, 35, '2025-07-01', '2025-07-04', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Card', 5400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (803, NULL, 131, 35, '2025-07-09', '2025-07-11', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Online', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (804, NULL, 131, 35, '2025-07-11', '2025-07-14', 'Checked-Out', 19440.00, 10.00, 0.00, 0.00, 'BankTransfer', 5832.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (807, NULL, 92, 35, '2025-07-24', '2025-07-26', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Cash', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (808, NULL, 132, 35, '2025-07-27', '2025-07-30', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'BankTransfer', 5400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (809, NULL, 29, 35, '2025-07-31', '2025-08-02', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Cash', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (957, NULL, 150, 41, '2025-08-17', '2025-08-19', 'Checked-Out', 44000.00, 10.00, 0.00, 0.00, 'BankTransfer', 8800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (961, NULL, 64, 41, '2025-08-29', '2025-09-03', 'Checked-Out', 47520.00, 10.00, 0.00, 0.00, 'Cash', 23760.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (962, NULL, 100, 41, '2025-09-04', '2025-09-06', 'Checked-In', 44000.00, 10.00, 0.00, 0.00, 'Cash', 8800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (963, NULL, 6, 41, '2025-09-06', '2025-09-10', 'Checked-Out', 47520.00, 10.00, 0.00, 0.00, 'Cash', 19008.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (965, NULL, 106, 41, '2025-09-16', '2025-09-21', 'Checked-Out', 44000.00, 10.00, 0.00, 0.00, 'Cash', 22000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (810, NULL, 25, 35, '2025-08-03', '2025-08-06', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Online', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (813, NULL, 95, 35, '2025-08-12', '2025-08-16', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Card', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (749, NULL, 12, 32, '2025-09-22', '2025-09-23', 'Checked-Out', 19800.00, 10.00, 2365.63, 0.00, 'Online', 1980.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (766, NULL, 6, 33, '2025-09-07', '2025-09-09', 'Checked-In', 19800.00, 10.00, 3850.91, 0.00, 'Online', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (777, NULL, 148, 34, '2025-07-12', '2025-07-13', 'Checked-Out', 19440.00, 10.00, 1302.52, 0.00, 'Online', 1944.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (779, NULL, 133, 34, '2025-07-15', '2025-07-16', 'Checked-Out', 18000.00, 10.00, 2523.36, 0.00, 'Card', 1800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (788, NULL, 95, 34, '2025-08-12', '2025-08-14', 'Checked-Out', 19800.00, 10.00, 2712.43, 0.00, 'Card', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (799, NULL, 78, 34, '2025-09-26', '2025-09-28', 'Checked-Out', 21384.00, 10.00, 3531.60, 0.00, 'Online', 4276.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (776, NULL, 15, 34, '2025-07-09', '2025-07-11', 'Checked-Out', 18000.00, 10.00, 1418.27, 0.00, 'Cash', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (791, NULL, 135, 34, '2025-08-20', '2025-08-24', 'Checked-Out', 19800.00, 10.00, 1950.51, 0.00, 'Online', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (806, NULL, 134, 35, '2025-07-18', '2025-07-23', 'Checked-Out', 19440.00, 10.00, 1441.53, 0.00, 'BankTransfer', 9720.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (740, NULL, 7, 32, '2025-08-15', '2025-08-20', 'Checked-Out', 21384.00, 10.00, 2626.72, 0.00, 'BankTransfer', 10692.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (741, NULL, 140, 32, '2025-08-20', '2025-08-23', 'Checked-Out', 19800.00, 10.00, 2432.15, 0.00, 'Card', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (768, NULL, 61, 33, '2025-09-14', '2025-09-17', 'Checked-Out', 19800.00, 10.00, 2432.15, 0.00, 'BankTransfer', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (772, NULL, 30, 33, '2025-09-30', '2025-10-01', 'Checked-In', 19800.00, 10.00, 2432.15, 0.00, 'Cash', 1980.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (747, NULL, 28, 32, '2025-09-12', '2025-09-15', 'Checked-Out', 21384.00, 10.00, 0.00, 4511.18, 'Cash', 6415.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (802, NULL, 99, 35, '2025-07-05', '2025-07-08', 'Checked-Out', 19440.00, 10.00, 2387.93, 0.00, 'Card', 5832.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (735, NULL, 72, 32, '2025-07-30', '2025-08-01', 'Cancelled', 18000.00, 10.00, 0.00, 0.00, 'Cash', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (736, NULL, 73, 32, '2025-08-01', '2025-08-05', 'Cancelled', 21384.00, 10.00, 0.00, 0.00, 'Online', 8553.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (783, NULL, 51, 34, '2025-07-27', '2025-08-01', 'Cancelled', 18000.00, 10.00, 2211.05, 0.00, 'Online', 9000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (751, NULL, 78, 32, '2025-09-30', '2025-10-03', 'Checked-In', 19800.00, 10.00, 0.00, 3413.81, 'Online', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (752, NULL, 55, 33, '2025-07-01', '2025-07-04', 'Checked-Out', 18000.00, 10.00, 0.00, 4647.52, 'BankTransfer', 5400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (765, NULL, 47, 33, '2025-09-05', '2025-09-07', 'Checked-Out', 21384.00, 10.00, 0.00, 4290.09, 'Card', 4276.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (767, NULL, 37, 33, '2025-09-10', '2025-09-12', 'Checked-Out', 19800.00, 10.00, 0.00, 3567.64, 'Card', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (796, NULL, 103, 34, '2025-09-13', '2025-09-15', 'Checked-Out', 21384.00, 10.00, 0.00, 4807.70, 'Card', 4276.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (816, NULL, 128, 35, '2025-08-25', '2025-08-27', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Online', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (818, NULL, 45, 35, '2025-09-01', '2025-09-06', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Cash', 9900.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (819, NULL, 29, 35, '2025-09-06', '2025-09-09', 'Checked-Out', 21384.00, 10.00, 0.00, 0.00, 'Online', 6415.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (820, NULL, 80, 35, '2025-09-11', '2025-09-14', 'Checked-In', 19800.00, 10.00, 0.00, 0.00, 'Card', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (822, NULL, 23, 35, '2025-09-21', '2025-09-25', 'Checked-In', 19800.00, 10.00, 0.00, 0.00, 'Cash', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (823, NULL, 18, 35, '2025-09-25', '2025-09-26', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Cash', 1980.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (824, NULL, 66, 35, '2025-09-26', '2025-09-28', 'Checked-Out', 21384.00, 10.00, 0.00, 0.00, 'Card', 4276.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (825, NULL, 77, 35, '2025-09-28', '2025-09-29', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Card', 1980.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (826, NULL, 135, 35, '2025-09-29', '2025-10-03', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Card', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (827, NULL, 93, 36, '2025-07-01', '2025-07-04', 'Checked-Out', 12000.00, 10.00, 0.00, 0.00, 'Online', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (830, NULL, 72, 36, '2025-07-11', '2025-07-13', 'Checked-Out', 12960.00, 10.00, 0.00, 0.00, 'Online', 2592.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (831, NULL, 22, 36, '2025-07-14', '2025-07-17', 'Checked-Out', 12000.00, 10.00, 0.00, 0.00, 'Cash', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (832, NULL, 110, 36, '2025-07-17', '2025-07-20', 'Checked-Out', 12000.00, 10.00, 0.00, 0.00, 'Cash', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (833, NULL, 104, 36, '2025-07-21', '2025-07-24', 'Checked-Out', 12000.00, 10.00, 0.00, 0.00, 'BankTransfer', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (838, NULL, 28, 36, '2025-08-07', '2025-08-08', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Online', 1320.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (840, NULL, 144, 36, '2025-08-13', '2025-08-16', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Card', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (842, NULL, 147, 36, '2025-08-22', '2025-08-26', 'Checked-Out', 14256.00, 10.00, 0.00, 0.00, 'Online', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (845, NULL, 88, 36, '2025-09-05', '2025-09-10', 'Checked-Out', 14256.00, 10.00, 0.00, 0.00, 'Online', 7128.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (847, NULL, 43, 36, '2025-09-16', '2025-09-18', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Online', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (849, NULL, 14, 36, '2025-09-23', '2025-09-26', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Cash', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (850, NULL, 46, 36, '2025-09-26', '2025-09-29', 'Checked-Out', 14256.00, 10.00, 0.00, 0.00, 'Cash', 4276.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (855, NULL, 56, 37, '2025-07-12', '2025-07-15', 'Checked-Out', 12960.00, 10.00, 0.00, 0.00, 'Cash', 3888.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (856, NULL, 35, 37, '2025-07-15', '2025-07-20', 'Checked-Out', 12000.00, 10.00, 0.00, 0.00, 'BankTransfer', 6000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (858, NULL, 96, 37, '2025-07-25', '2025-07-29', 'Checked-Out', 12960.00, 10.00, 0.00, 0.00, 'BankTransfer', 5184.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (860, NULL, 147, 37, '2025-08-04', '2025-08-06', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Cash', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (861, NULL, 115, 37, '2025-08-08', '2025-08-13', 'Checked-Out', 14256.00, 10.00, 0.00, 0.00, 'BankTransfer', 7128.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (862, NULL, 65, 37, '2025-08-13', '2025-08-16', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'BankTransfer', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (863, NULL, 149, 37, '2025-08-16', '2025-08-20', 'Checked-In', 14256.00, 10.00, 0.00, 0.00, 'Card', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (865, NULL, 73, 37, '2025-08-23', '2025-08-26', 'Checked-Out', 14256.00, 10.00, 0.00, 0.00, 'Cash', 4276.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (870, NULL, 136, 37, '2025-09-11', '2025-09-14', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Cash', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (871, NULL, 73, 37, '2025-09-16', '2025-09-18', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'BankTransfer', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (872, NULL, 27, 37, '2025-09-19', '2025-09-21', 'Checked-Out', 14256.00, 10.00, 0.00, 0.00, 'Online', 2851.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (873, NULL, 133, 37, '2025-09-22', '2025-09-24', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'BankTransfer', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1056, NULL, 84, 45, '2025-09-18', '2025-09-22', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Cash', 10560.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1057, NULL, 147, 45, '2025-09-23', '2025-09-25', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Online', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1058, NULL, 129, 45, '2025-09-27', '2025-10-01', 'Checked-Out', 28512.00, 10.00, 0.00, 0.00, 'Online', 11404.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (874, NULL, 45, 37, '2025-09-25', '2025-09-29', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Cash', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (876, NULL, 28, 38, '2025-07-01', '2025-07-05', 'Checked-In', 12000.00, 10.00, 0.00, 0.00, 'Cash', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (877, NULL, 21, 38, '2025-07-05', '2025-07-08', 'Checked-Out', 12960.00, 10.00, 0.00, 0.00, 'BankTransfer', 3888.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (878, NULL, 142, 38, '2025-07-09', '2025-07-13', 'Checked-In', 12000.00, 10.00, 0.00, 0.00, 'BankTransfer', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (879, NULL, 103, 38, '2025-07-14', '2025-07-15', 'Checked-Out', 12000.00, 10.00, 0.00, 0.00, 'Card', 1200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (880, NULL, 13, 38, '2025-07-17', '2025-07-20', 'Checked-Out', 12000.00, 10.00, 0.00, 0.00, 'BankTransfer', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (881, NULL, 26, 38, '2025-07-21', '2025-07-26', 'Checked-Out', 12000.00, 10.00, 0.00, 0.00, 'Online', 6000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (885, NULL, 11, 38, '2025-08-03', '2025-08-05', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Card', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (886, NULL, 147, 38, '2025-08-05', '2025-08-07', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Online', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (892, NULL, 81, 38, '2025-08-24', '2025-08-29', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Cash', 6600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (893, NULL, 88, 38, '2025-08-30', '2025-09-02', 'Checked-Out', 14256.00, 10.00, 0.00, 0.00, 'Cash', 4276.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (894, NULL, 59, 38, '2025-09-04', '2025-09-08', 'Checked-In', 13200.00, 10.00, 0.00, 0.00, 'BankTransfer', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (895, NULL, 28, 38, '2025-09-09', '2025-09-12', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'BankTransfer', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (852, NULL, 106, 37, '2025-07-01', '2025-07-04', 'Checked-Out', 12000.00, 10.00, 1112.58, 0.00, 'Cash', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (839, NULL, 124, 36, '2025-08-10', '2025-08-12', 'Checked-Out', 13200.00, 10.00, 1621.43, 0.00, 'Card', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (869, NULL, 76, 37, '2025-09-06', '2025-09-10', 'Checked-Out', 14256.00, 10.00, 1226.68, 0.00, 'Cash', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (875, NULL, 81, 37, '2025-09-29', '2025-10-04', 'Checked-In', 13200.00, 10.00, 687.19, 0.00, 'Cash', 6600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (815, NULL, 5, 35, '2025-08-21', '2025-08-24', 'Checked-Out', 19800.00, 10.00, 2307.45, 0.00, 'BankTransfer', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (828, NULL, 2, 36, '2025-07-05', '2025-07-08', 'Checked-Out', 12960.00, 10.00, 2299.07, 0.00, 'Cash', 3888.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (882, NULL, 57, 38, '2025-07-27', '2025-07-29', 'Cancelled', 12000.00, 10.00, 0.00, 0.00, 'BankTransfer', 2400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (841, NULL, 52, 36, '2025-08-16', '2025-08-21', 'Checked-Out', 14256.00, 10.00, 2695.84, 0.00, 'Online', 7128.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (844, NULL, 129, 36, '2025-09-02', '2025-09-03', 'Checked-In', 13200.00, 10.00, 972.30, 0.00, 'Cash', 1320.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (854, NULL, 18, 37, '2025-07-08', '2025-07-11', 'Checked-Out', 12000.00, 10.00, 1474.03, 0.00, 'Card', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (866, NULL, 84, 37, '2025-08-27', '2025-09-01', 'Checked-Out', 13200.00, 10.00, 1621.43, 0.00, 'Cash', 6600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (867, NULL, 141, 37, '2025-09-02', '2025-09-03', 'Checked-Out', 13200.00, 10.00, 1621.43, 0.00, 'Online', 1320.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (883, NULL, 93, 38, '2025-07-30', '2025-07-31', 'Checked-Out', 12000.00, 10.00, 1474.03, 0.00, 'Online', 1200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (890, NULL, 61, 38, '2025-08-19', '2025-08-21', 'Checked-In', 13200.00, 10.00, 1621.43, 0.00, 'Cash', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (837, NULL, 3, 36, '2025-08-01', '2025-08-06', 'Checked-Out', 14256.00, 10.00, 1751.15, 0.00, 'Cash', 7128.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (884, NULL, 148, 38, '2025-08-01', '2025-08-03', 'Cancelled', 14256.00, 10.00, 0.00, 0.00, 'Card', 2851.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (817, NULL, 29, 35, '2025-08-27', '2025-08-31', 'Checked-Out', 19800.00, 10.00, 0.00, 2621.12, 'Online', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (821, NULL, 65, 35, '2025-09-15', '2025-09-19', 'Checked-Out', 19800.00, 10.00, 0.00, 5707.30, 'Cash', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (835, NULL, 110, 36, '2025-07-27', '2025-07-28', 'Checked-In', 12000.00, 10.00, 0.00, 1860.87, 'Online', 1200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (836, NULL, 40, 36, '2025-07-29', '2025-07-31', 'Checked-In', 12000.00, 10.00, 0.00, 2687.18, 'Card', 2400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (851, NULL, 52, 36, '2025-09-30', '2025-10-03', 'Checked-Out', 13200.00, 10.00, 0.00, 3944.41, 'Cash', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (857, NULL, 108, 37, '2025-07-21', '2025-07-23', 'Checked-In', 12000.00, 10.00, 0.00, 3416.32, 'Online', 2400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (864, NULL, 131, 37, '2025-08-21', '2025-08-23', 'Checked-Out', 13200.00, 10.00, 0.00, 2420.11, 'Online', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (898, NULL, 85, 38, '2025-09-21', '2025-09-23', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Cash', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (899, NULL, 29, 38, '2025-09-24', '2025-09-27', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Online', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (901, NULL, 144, 39, '2025-07-01', '2025-07-04', 'Checked-In', 12000.00, 10.00, 0.00, 0.00, 'BankTransfer', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (903, NULL, 103, 39, '2025-07-11', '2025-07-15', 'Checked-In', 12960.00, 10.00, 0.00, 0.00, 'Card', 5184.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (905, NULL, 145, 39, '2025-07-19', '2025-07-20', 'Checked-Out', 12960.00, 10.00, 0.00, 0.00, 'BankTransfer', 1296.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (906, NULL, 78, 39, '2025-07-21', '2025-07-26', 'Checked-Out', 12000.00, 10.00, 0.00, 0.00, 'Online', 6000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (909, NULL, 108, 39, '2025-08-05', '2025-08-08', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'BankTransfer', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (910, NULL, 103, 39, '2025-08-09', '2025-08-10', 'Checked-Out', 14256.00, 10.00, 0.00, 0.00, 'Online', 1425.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (912, NULL, 66, 39, '2025-08-15', '2025-08-20', 'Checked-Out', 14256.00, 10.00, 0.00, 0.00, 'Online', 7128.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (913, NULL, 28, 39, '2025-08-20', '2025-08-24', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Online', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (914, NULL, 91, 39, '2025-08-26', '2025-08-30', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Online', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (915, NULL, 21, 39, '2025-09-01', '2025-09-04', 'Checked-In', 13200.00, 10.00, 0.00, 0.00, 'Online', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (916, NULL, 2, 39, '2025-09-04', '2025-09-08', 'Checked-In', 13200.00, 10.00, 0.00, 0.00, 'BankTransfer', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (918, NULL, 17, 39, '2025-09-12', '2025-09-16', 'Checked-In', 14256.00, 10.00, 0.00, 0.00, 'Card', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (920, NULL, 48, 39, '2025-09-22', '2025-09-27', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'BankTransfer', 6600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (921, NULL, 23, 39, '2025-09-27', '2025-09-30', 'Checked-Out', 14256.00, 10.00, 0.00, 0.00, 'Cash', 4276.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (923, NULL, 89, 40, '2025-07-04', '2025-07-07', 'Checked-Out', 12960.00, 10.00, 0.00, 0.00, 'Cash', 3888.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (924, NULL, 7, 40, '2025-07-07', '2025-07-10', 'Checked-Out', 12000.00, 10.00, 0.00, 0.00, 'BankTransfer', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (926, NULL, 61, 40, '2025-07-13', '2025-07-16', 'Checked-Out', 12000.00, 10.00, 0.00, 0.00, 'BankTransfer', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (927, NULL, 92, 40, '2025-07-17', '2025-07-21', 'Checked-Out', 12000.00, 10.00, 0.00, 0.00, 'Card', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (930, NULL, 68, 40, '2025-07-31', '2025-08-02', 'Checked-Out', 12000.00, 10.00, 0.00, 0.00, 'Cash', 2400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (931, NULL, 112, 40, '2025-08-02', '2025-08-07', 'Checked-Out', 14256.00, 10.00, 0.00, 0.00, 'Online', 7128.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (933, NULL, 9, 40, '2025-08-11', '2025-08-16', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Online', 6600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (935, NULL, 55, 40, '2025-08-23', '2025-08-26', 'Checked-Out', 14256.00, 10.00, 0.00, 0.00, 'BankTransfer', 4276.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (936, NULL, 42, 40, '2025-08-27', '2025-08-29', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Online', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (937, NULL, 54, 40, '2025-08-31', '2025-09-02', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Cash', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1443, NULL, 1, 20, '2025-11-10', '2025-11-12', 'Booked', 20000.00, 10.00, 0.00, 0.00, NULL, 5000.00, DEFAULT, '2025-10-07 15:40:18.738716+05:30');
INSERT INTO public.booking VALUES (1127, NULL, 69, 48, '2025-09-04', '2025-09-07', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Cash', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1129, NULL, 81, 48, '2025-09-11', '2025-09-12', 'Checked-In', 26400.00, 10.00, 0.00, 0.00, 'Card', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (938, NULL, 44, 40, '2025-09-04', '2025-09-08', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'BankTransfer', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (939, NULL, 9, 40, '2025-09-09', '2025-09-11', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Online', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (942, NULL, 19, 40, '2025-09-19', '2025-09-23', 'Checked-Out', 14256.00, 10.00, 0.00, 0.00, 'Card', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (943, NULL, 63, 40, '2025-09-24', '2025-09-28', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Online', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (944, NULL, 117, 40, '2025-09-30', '2025-10-03', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Cash', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (946, NULL, 46, 41, '2025-07-07', '2025-07-11', 'Checked-Out', 40000.00, 10.00, 0.00, 0.00, 'Card', 16000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (947, NULL, 63, 41, '2025-07-12', '2025-07-15', 'Checked-Out', 43200.00, 10.00, 0.00, 0.00, 'BankTransfer', 12960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (949, NULL, 20, 41, '2025-07-17', '2025-07-19', 'Checked-In', 40000.00, 10.00, 0.00, 0.00, 'Cash', 8000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (950, NULL, 29, 41, '2025-07-19', '2025-07-21', 'Checked-Out', 43200.00, 10.00, 0.00, 0.00, 'Cash', 8640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (951, NULL, 19, 41, '2025-07-23', '2025-07-26', 'Checked-Out', 40000.00, 10.00, 0.00, 0.00, 'BankTransfer', 12000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (953, NULL, 86, 41, '2025-07-29', '2025-07-31', 'Checked-Out', 40000.00, 10.00, 0.00, 0.00, 'Card', 8000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (954, NULL, 98, 41, '2025-08-02', '2025-08-07', 'Checked-Out', 47520.00, 10.00, 0.00, 0.00, 'Online', 23760.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (955, NULL, 27, 41, '2025-08-09', '2025-08-12', 'Checked-In', 47520.00, 10.00, 0.00, 0.00, 'Cash', 14256.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (967, NULL, 31, 41, '2025-09-28', '2025-10-01', 'Checked-Out', 44000.00, 10.00, 0.00, 0.00, 'Online', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (969, NULL, 8, 42, '2025-07-03', '2025-07-07', 'Checked-Out', 40000.00, 10.00, 0.00, 0.00, 'Online', 16000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (970, NULL, 112, 42, '2025-07-08', '2025-07-13', 'Checked-Out', 40000.00, 10.00, 0.00, 0.00, 'BankTransfer', 20000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (971, NULL, 76, 42, '2025-07-14', '2025-07-17', 'Checked-Out', 40000.00, 10.00, 0.00, 0.00, 'Online', 12000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (972, NULL, 135, 42, '2025-07-18', '2025-07-20', 'Checked-Out', 43200.00, 10.00, 0.00, 0.00, 'BankTransfer', 8640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (975, NULL, 47, 42, '2025-07-31', '2025-08-03', 'Checked-Out', 40000.00, 10.00, 0.00, 0.00, 'Online', 12000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (977, NULL, 91, 42, '2025-08-09', '2025-08-13', 'Checked-Out', 47520.00, 10.00, 0.00, 0.00, 'Cash', 19008.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (902, NULL, 39, 39, '2025-07-06', '2025-07-10', 'Checked-Out', 12000.00, 10.00, 811.50, 0.00, 'Cash', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (904, NULL, 46, 39, '2025-07-15', '2025-07-18', 'Checked-In', 12000.00, 10.00, 640.91, 0.00, 'Online', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (925, NULL, 20, 40, '2025-07-10', '2025-07-12', 'Checked-Out', 12000.00, 10.00, 1707.49, 0.00, 'Online', 2400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (928, NULL, 137, 40, '2025-07-22', '2025-07-26', 'Checked-Out', 12000.00, 10.00, 890.54, 0.00, 'BankTransfer', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (958, NULL, 28, 41, '2025-08-20', '2025-08-23', 'Checked-Out', 44000.00, 10.00, 5024.41, 0.00, 'Online', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (960, NULL, 24, 41, '2025-08-28', '2025-08-29', 'Checked-Out', 44000.00, 10.00, 6589.13, 0.00, 'Cash', 4400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (966, NULL, 5, 41, '2025-09-23', '2025-09-26', 'Checked-Out', 44000.00, 10.00, 5997.35, 0.00, 'BankTransfer', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (917, NULL, 124, 39, '2025-09-08', '2025-09-11', 'Checked-In', 13200.00, 10.00, 0.00, 2007.04, 'BankTransfer', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (919, NULL, 126, 39, '2025-09-17', '2025-09-21', 'Checked-Out', 13200.00, 10.00, 779.13, 0.00, 'Online', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (934, NULL, 6, 40, '2025-08-18', '2025-08-23', 'Checked-Out', 13200.00, 10.00, 1552.38, 0.00, 'Cash', 6600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (945, NULL, 62, 41, '2025-07-01', '2025-07-05', 'Checked-Out', 40000.00, 10.00, 4870.49, 0.00, 'Cash', 16000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (897, NULL, 59, 38, '2025-09-16', '2025-09-20', 'Checked-In', 13200.00, 10.00, 1621.43, 0.00, 'Online', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (948, NULL, 30, 41, '2025-07-16', '2025-07-17', 'Checked-In', 40000.00, 10.00, 4913.43, 0.00, 'Cash', 4000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (964, NULL, 98, 41, '2025-09-12', '2025-09-14', 'Checked-In', 47520.00, 10.00, 5837.16, 0.00, 'Cash', 9504.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (908, NULL, 103, 39, '2025-08-02', '2025-08-03', 'Cancelled', 14256.00, 10.00, 0.00, 0.00, 'Cash', 1425.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (941, NULL, 62, 40, '2025-09-15', '2025-09-18', 'Cancelled', 13200.00, 10.00, 0.00, 0.00, 'Cash', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (900, NULL, 62, 38, '2025-09-29', '2025-10-01', 'Cancelled', 13200.00, 10.00, 2097.68, 0.00, 'Card', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (959, NULL, 53, 41, '2025-08-24', '2025-08-26', 'Checked-Out', 44000.00, 10.00, 0.00, 10725.51, 'Cash', 8800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (968, NULL, 133, 42, '2025-07-01', '2025-07-02', 'Checked-Out', 40000.00, 10.00, 0.00, 11630.91, 'Card', 4000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (976, NULL, 78, 42, '2025-08-04', '2025-08-09', 'Checked-Out', 44000.00, 10.00, 0.00, 12829.50, 'Online', 22000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (981, NULL, 109, 42, '2025-08-26', '2025-08-31', 'Checked-Out', 44000.00, 10.00, 0.00, 0.00, 'Cash', 22000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (982, NULL, 20, 42, '2025-08-31', '2025-09-02', 'Checked-Out', 44000.00, 10.00, 0.00, 0.00, 'Cash', 8800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (983, NULL, 53, 42, '2025-09-03', '2025-09-08', 'Checked-Out', 44000.00, 10.00, 0.00, 0.00, 'Online', 22000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (987, NULL, 149, 42, '2025-09-26', '2025-09-27', 'Checked-Out', 47520.00, 10.00, 0.00, 0.00, 'Online', 4752.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (989, NULL, 17, 43, '2025-07-01', '2025-07-05', 'Checked-Out', 40000.00, 10.00, 0.00, 0.00, 'BankTransfer', 16000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (992, NULL, 126, 43, '2025-07-11', '2025-07-14', 'Checked-Out', 43200.00, 10.00, 0.00, 0.00, 'Cash', 12960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (994, NULL, 68, 43, '2025-07-18', '2025-07-23', 'Checked-Out', 43200.00, 10.00, 0.00, 0.00, 'BankTransfer', 21600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (995, NULL, 62, 43, '2025-07-24', '2025-07-26', 'Checked-Out', 40000.00, 10.00, 0.00, 0.00, 'Cash', 8000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (997, NULL, 59, 43, '2025-08-01', '2025-08-05', 'Checked-Out', 47520.00, 10.00, 0.00, 0.00, 'Cash', 19008.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (998, NULL, 140, 43, '2025-08-05', '2025-08-06', 'Checked-Out', 44000.00, 10.00, 0.00, 0.00, 'Online', 4400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1000, NULL, 110, 43, '2025-08-14', '2025-08-16', 'Checked-Out', 44000.00, 10.00, 0.00, 0.00, 'Cash', 8800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1004, NULL, 124, 43, '2025-09-03', '2025-09-04', 'Checked-In', 44000.00, 10.00, 0.00, 0.00, 'Cash', 4400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1008, NULL, 117, 43, '2025-09-17', '2025-09-19', 'Checked-Out', 44000.00, 10.00, 0.00, 0.00, 'Cash', 8800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1010, NULL, 63, 43, '2025-09-24', '2025-09-27', 'Checked-Out', 44000.00, 10.00, 0.00, 0.00, 'Card', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1011, NULL, 82, 43, '2025-09-28', '2025-10-01', 'Checked-In', 44000.00, 10.00, 0.00, 0.00, 'BankTransfer', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1012, NULL, 76, 44, '2025-07-01', '2025-07-02', 'Checked-Out', 24000.00, 10.00, 0.00, 0.00, 'Card', 2400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1013, NULL, 44, 44, '2025-07-04', '2025-07-09', 'Checked-Out', 25920.00, 10.00, 0.00, 0.00, 'Online', 12960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1017, NULL, 20, 44, '2025-07-27', '2025-07-29', 'Checked-In', 24000.00, 10.00, 0.00, 0.00, 'BankTransfer', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1020, NULL, 3, 44, '2025-08-06', '2025-08-10', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Cash', 10560.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1021, NULL, 41, 44, '2025-08-10', '2025-08-15', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'BankTransfer', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1022, NULL, 74, 44, '2025-08-16', '2025-08-18', 'Checked-Out', 28512.00, 10.00, 0.00, 0.00, 'Online', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1024, NULL, 52, 44, '2025-08-23', '2025-08-28', 'Checked-Out', 28512.00, 10.00, 0.00, 0.00, 'Online', 14256.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1026, NULL, 139, 44, '2025-09-01', '2025-09-05', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Cash', 10560.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1035, NULL, 34, 45, '2025-07-05', '2025-07-06', 'Checked-Out', 25920.00, 10.00, 0.00, 0.00, 'Online', 2592.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1036, NULL, 26, 45, '2025-07-07', '2025-07-10', 'Checked-Out', 24000.00, 10.00, 0.00, 0.00, 'BankTransfer', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1037, NULL, 120, 45, '2025-07-10', '2025-07-14', 'Checked-Out', 24000.00, 10.00, 0.00, 0.00, 'Cash', 9600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1041, NULL, 135, 45, '2025-07-23', '2025-07-25', 'Checked-In', 24000.00, 10.00, 0.00, 0.00, 'Card', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1042, NULL, 11, 45, '2025-07-26', '2025-07-29', 'Checked-Out', 25920.00, 10.00, 0.00, 0.00, 'Cash', 7776.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1043, NULL, 105, 45, '2025-07-29', '2025-08-01', 'Checked-Out', 24000.00, 10.00, 0.00, 0.00, 'Online', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1044, NULL, 113, 45, '2025-08-02', '2025-08-04', 'Checked-Out', 28512.00, 10.00, 0.00, 0.00, 'Online', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1045, NULL, 36, 45, '2025-08-04', '2025-08-09', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Card', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1047, NULL, 8, 45, '2025-08-12', '2025-08-17', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'BankTransfer', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1048, NULL, 18, 45, '2025-08-18', '2025-08-22', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Online', 10560.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1049, NULL, 32, 45, '2025-08-23', '2025-08-25', 'Checked-Out', 28512.00, 10.00, 0.00, 0.00, 'Cash', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1050, NULL, 83, 45, '2025-08-25', '2025-08-28', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Cash', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1051, NULL, 47, 45, '2025-08-29', '2025-08-30', 'Checked-Out', 28512.00, 10.00, 0.00, 0.00, 'Cash', 2851.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1055, NULL, 108, 45, '2025-09-15', '2025-09-18', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Cash', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1059, NULL, 92, 46, '2025-07-01', '2025-07-04', 'Checked-In', 24000.00, 10.00, 0.00, 0.00, 'Online', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (978, NULL, 19, 42, '2025-08-13', '2025-08-15', 'Checked-In', 44000.00, 10.00, 8579.07, 0.00, 'Card', 8800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (980, NULL, 43, 42, '2025-08-21', '2025-08-24', 'Checked-Out', 44000.00, 10.00, 5404.78, 0.00, 'Card', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (991, NULL, 88, 43, '2025-07-09', '2025-07-10', 'Cancelled', 40000.00, 10.00, 0.00, 0.00, 'Cash', 4000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1019, NULL, 121, 44, '2025-08-03', '2025-08-05', 'Checked-Out', 26400.00, 10.00, 3164.42, 0.00, 'Online', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1033, NULL, 32, 44, '2025-09-27', '2025-10-01', 'Checked-In', 28512.00, 10.00, 5217.89, 0.00, 'Online', 11404.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (979, NULL, 84, 42, '2025-08-16', '2025-08-19', 'Checked-Out', 47520.00, 10.00, 4675.76, 0.00, 'Online', 14256.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (988, NULL, 74, 42, '2025-09-29', '2025-10-04', 'Checked-Out', 44000.00, 10.00, 7436.89, 0.00, 'Online', 22000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1001, NULL, 91, 43, '2025-08-17', '2025-08-22', 'Checked-In', 44000.00, 10.00, 5586.14, 0.00, 'BankTransfer', 22000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1029, NULL, 137, 44, '2025-09-13', '2025-09-15', 'Checked-In', 28512.00, 10.00, 2668.71, 0.00, 'Card', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1032, NULL, 132, 44, '2025-09-23', '2025-09-26', 'Checked-Out', 26400.00, 10.00, 3376.26, 0.00, 'Online', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1034, NULL, 15, 45, '2025-07-01', '2025-07-03', 'Checked-Out', 24000.00, 10.00, 1265.78, 0.00, 'Online', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1054, NULL, 97, 45, '2025-09-09', '2025-09-14', 'Checked-Out', 26400.00, 10.00, 4482.44, 0.00, 'Online', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (985, NULL, 115, 42, '2025-09-17', '2025-09-21', 'Checked-Out', 44000.00, 10.00, 5098.53, 0.00, 'Cash', 17600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1023, NULL, 113, 44, '2025-08-19', '2025-08-22', 'Checked-Out', 26400.00, 10.00, 3242.87, 0.00, 'Card', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1046, NULL, 127, 45, '2025-08-10', '2025-08-12', 'Checked-Out', 26400.00, 10.00, 3242.87, 0.00, 'Card', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1007, NULL, 37, 43, '2025-09-12', '2025-09-16', 'Checked-Out', 47520.00, 10.00, 5837.16, 0.00, 'Online', 19008.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1015, NULL, 62, 44, '2025-07-17', '2025-07-19', 'Cancelled', 24000.00, 10.00, 0.00, 0.00, 'Cash', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1039, NULL, 70, 45, '2025-07-19', '2025-07-20', 'Cancelled', 25920.00, 10.00, 0.00, 0.00, 'Online', 2592.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1040, NULL, 147, 45, '2025-07-21', '2025-07-23', 'Cancelled', 24000.00, 10.00, 0.00, 0.00, 'Cash', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1028, NULL, 88, 44, '2025-09-10', '2025-09-11', 'Checked-Out', 26400.00, 10.00, 0.00, 6722.41, 'Cash', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1052, NULL, 134, 45, '2025-08-31', '2025-09-04', 'Checked-Out', 26400.00, 10.00, 0.00, 5706.79, 'Cash', 10560.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (986, NULL, 11, 42, '2025-09-21', '2025-09-25', 'Checked-Out', 44000.00, 10.00, 7972.05, 5888.84, 'Online', 17600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (999, NULL, 18, 43, '2025-08-07', '2025-08-12', 'Checked-Out', 44000.00, 10.00, 5404.78, 12482.77, 'Cash', 22000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1060, NULL, 114, 46, '2025-07-05', '2025-07-07', 'Checked-In', 25920.00, 10.00, 0.00, 0.00, 'Cash', 5184.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1062, NULL, 103, 46, '2025-07-11', '2025-07-13', 'Checked-Out', 25920.00, 10.00, 0.00, 0.00, 'Online', 5184.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1063, NULL, 45, 46, '2025-07-13', '2025-07-15', 'Checked-In', 24000.00, 10.00, 0.00, 0.00, 'BankTransfer', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1064, NULL, 47, 46, '2025-07-16', '2025-07-18', 'Checked-Out', 24000.00, 10.00, 0.00, 0.00, 'Online', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1065, NULL, 145, 46, '2025-07-19', '2025-07-20', 'Checked-Out', 25920.00, 10.00, 0.00, 0.00, 'Card', 2592.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1066, NULL, 122, 46, '2025-07-20', '2025-07-23', 'Checked-Out', 24000.00, 10.00, 0.00, 0.00, 'Online', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1067, NULL, 128, 46, '2025-07-24', '2025-07-27', 'Checked-Out', 24000.00, 10.00, 0.00, 0.00, 'Cash', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1068, NULL, 58, 46, '2025-07-28', '2025-07-30', 'Checked-Out', 24000.00, 10.00, 0.00, 0.00, 'BankTransfer', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1071, NULL, 117, 46, '2025-08-08', '2025-08-09', 'Checked-Out', 28512.00, 10.00, 0.00, 0.00, 'BankTransfer', 2851.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1075, NULL, 19, 46, '2025-08-23', '2025-08-25', 'Checked-In', 28512.00, 10.00, 0.00, 0.00, 'Card', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1076, NULL, 82, 46, '2025-08-26', '2025-08-28', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'BankTransfer', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1078, NULL, 19, 46, '2025-09-02', '2025-09-07', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Online', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1079, NULL, 85, 46, '2025-09-09', '2025-09-11', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Online', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1080, NULL, 122, 46, '2025-09-13', '2025-09-18', 'Checked-Out', 28512.00, 10.00, 0.00, 0.00, 'Online', 14256.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1081, NULL, 4, 46, '2025-09-19', '2025-09-22', 'Checked-Out', 28512.00, 10.00, 0.00, 0.00, 'Cash', 8553.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1082, NULL, 133, 46, '2025-09-23', '2025-09-28', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'BankTransfer', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1083, NULL, 52, 46, '2025-09-29', '2025-10-04', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Online', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1086, NULL, 44, 47, '2025-07-08', '2025-07-13', 'Checked-Out', 24000.00, 10.00, 0.00, 0.00, 'Cash', 12000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1087, NULL, 16, 47, '2025-07-13', '2025-07-16', 'Checked-In', 24000.00, 10.00, 0.00, 0.00, 'Online', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1090, NULL, 5, 47, '2025-07-24', '2025-07-26', 'Checked-Out', 24000.00, 10.00, 0.00, 0.00, 'Card', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1093, NULL, 71, 47, '2025-08-03', '2025-08-05', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Cash', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1095, NULL, 72, 47, '2025-08-09', '2025-08-11', 'Checked-Out', 28512.00, 10.00, 0.00, 0.00, 'Card', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1098, NULL, 109, 47, '2025-08-17', '2025-08-19', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'BankTransfer', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1099, NULL, 92, 47, '2025-08-19', '2025-08-21', 'Checked-In', 26400.00, 10.00, 0.00, 0.00, 'Card', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1100, NULL, 127, 47, '2025-08-21', '2025-08-24', 'Checked-In', 26400.00, 10.00, 0.00, 0.00, 'Cash', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1101, NULL, 63, 47, '2025-08-24', '2025-08-29', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Cash', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1102, NULL, 69, 47, '2025-08-30', '2025-09-04', 'Checked-Out', 28512.00, 10.00, 0.00, 0.00, 'Online', 14256.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1103, NULL, 22, 47, '2025-09-05', '2025-09-09', 'Checked-Out', 28512.00, 10.00, 0.00, 0.00, 'Online', 11404.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1104, NULL, 141, 47, '2025-09-11', '2025-09-14', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Online', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1229, NULL, 87, 52, '2025-09-28', '2025-09-30', 'Cancelled', 19800.00, 10.00, 0.00, 0.00, 'Cash', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1105, NULL, 53, 47, '2025-09-15', '2025-09-20', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Cash', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1107, NULL, 117, 47, '2025-09-24', '2025-09-28', 'Checked-In', 26400.00, 10.00, 0.00, 0.00, 'Cash', 10560.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1108, NULL, 10, 47, '2025-09-29', '2025-10-01', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Online', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1110, NULL, 100, 48, '2025-07-04', '2025-07-06', 'Checked-Out', 25920.00, 10.00, 0.00, 0.00, 'BankTransfer', 5184.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1111, NULL, 87, 48, '2025-07-08', '2025-07-12', 'Checked-Out', 24000.00, 10.00, 0.00, 0.00, 'Cash', 9600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1112, NULL, 144, 48, '2025-07-12', '2025-07-15', 'Checked-Out', 25920.00, 10.00, 0.00, 0.00, 'Cash', 7776.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1113, NULL, 54, 48, '2025-07-15', '2025-07-20', 'Checked-Out', 24000.00, 10.00, 0.00, 0.00, 'BankTransfer', 12000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1116, NULL, 57, 48, '2025-07-27', '2025-07-30', 'Checked-Out', 24000.00, 10.00, 0.00, 0.00, 'BankTransfer', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1117, NULL, 131, 48, '2025-07-30', '2025-08-01', 'Checked-In', 24000.00, 10.00, 0.00, 0.00, 'Online', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1119, NULL, 1, 48, '2025-08-09', '2025-08-11', 'Checked-Out', 28512.00, 10.00, 0.00, 0.00, 'Online', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1121, NULL, 53, 48, '2025-08-13', '2025-08-14', 'Checked-In', 26400.00, 10.00, 0.00, 0.00, 'Card', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1122, NULL, 64, 48, '2025-08-15', '2025-08-19', 'Checked-In', 28512.00, 10.00, 0.00, 0.00, 'Cash', 11404.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1123, NULL, 34, 48, '2025-08-20', '2025-08-25', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Online', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1124, NULL, 109, 48, '2025-08-26', '2025-08-27', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Card', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1126, NULL, 30, 48, '2025-08-31', '2025-09-02', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Cash', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1130, NULL, 1, 48, '2025-09-13', '2025-09-16', 'Checked-In', 28512.00, 10.00, 0.00, 0.00, 'Online', 8553.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1131, NULL, 84, 48, '2025-09-16', '2025-09-20', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Online', 10560.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1133, NULL, 4, 48, '2025-09-23', '2025-09-28', 'Checked-Out', 26400.00, 10.00, 0.00, 0.00, 'Cash', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1136, NULL, 118, 49, '2025-07-05', '2025-07-07', 'Checked-Out', 19440.00, 10.00, 0.00, 0.00, 'Cash', 3888.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1137, NULL, 65, 49, '2025-07-09', '2025-07-11', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Cash', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1139, NULL, 70, 49, '2025-07-17', '2025-07-20', 'Checked-In', 18000.00, 10.00, 0.00, 0.00, 'Cash', 5400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1140, NULL, 66, 49, '2025-07-21', '2025-07-26', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Cash', 9000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1084, NULL, 56, 47, '2025-07-01', '2025-07-03', 'Checked-Out', 24000.00, 10.00, 2063.12, 0.00, 'Card', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1061, NULL, 8, 46, '2025-07-08', '2025-07-10', 'Cancelled', 24000.00, 10.00, 0.00, 0.00, 'Online', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1114, NULL, 101, 48, '2025-07-20', '2025-07-23', 'Checked-Out', 24000.00, 10.00, 4263.05, 0.00, 'Card', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1069, NULL, 93, 46, '2025-07-31', '2025-08-03', 'Checked-Out', 24000.00, 10.00, 3124.78, 0.00, 'BankTransfer', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1109, NULL, 147, 48, '2025-07-01', '2025-07-02', 'Checked-Out', 24000.00, 10.00, 1824.26, 0.00, 'Cash', 2400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1085, NULL, 25, 47, '2025-07-04', '2025-07-06', 'Checked-In', 25920.00, 10.00, 3183.90, 0.00, 'Card', 5184.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1091, NULL, 73, 47, '2025-07-27', '2025-07-31', 'Checked-In', 24000.00, 10.00, 2948.06, 0.00, 'BankTransfer', 9600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1096, NULL, 84, 47, '2025-08-12', '2025-08-13', 'Checked-In', 26400.00, 10.00, 3242.87, 0.00, 'Cash', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1106, NULL, 102, 47, '2025-09-20', '2025-09-23', 'Checked-Out', 28512.00, 10.00, 3502.30, 0.00, 'Online', 8553.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1135, NULL, 140, 49, '2025-07-01', '2025-07-05', 'Checked-Out', 18000.00, 10.00, 2211.05, 0.00, 'Online', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1092, NULL, 62, 47, '2025-08-01', '2025-08-02', 'Checked-In', 28512.00, 10.00, 3502.30, 0.00, 'Online', 2851.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1074, NULL, 46, 46, '2025-08-17', '2025-08-21', 'Cancelled', 26400.00, 10.00, 0.00, 0.00, 'BankTransfer', 10560.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1077, NULL, 32, 46, '2025-08-29', '2025-09-01', 'Cancelled', 28512.00, 10.00, 0.00, 0.00, 'Cash', 8553.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1097, NULL, 4, 47, '2025-08-15', '2025-08-17', 'Cancelled', 28512.00, 10.00, 0.00, 0.00, 'Online', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1072, NULL, 41, 46, '2025-08-09', '2025-08-11', 'Checked-Out', 28512.00, 10.00, 0.00, 6817.37, 'BankTransfer', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1089, NULL, 86, 47, '2025-07-21', '2025-07-23', 'Checked-In', 24000.00, 10.00, 0.00, 2818.26, 'Cash', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1138, NULL, 47, 49, '2025-07-12', '2025-07-15', 'Checked-Out', 19440.00, 10.00, 0.00, 5740.95, 'Online', 5832.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1142, NULL, 87, 49, '2025-07-31', '2025-08-04', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'BankTransfer', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1146, NULL, 1, 49, '2025-08-13', '2025-08-17', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Online', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1147, NULL, 100, 49, '2025-08-19', '2025-08-20', 'Checked-In', 19800.00, 10.00, 0.00, 0.00, 'Cash', 1980.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1148, NULL, 69, 49, '2025-08-22', '2025-08-23', 'Checked-Out', 21384.00, 10.00, 0.00, 0.00, 'Cash', 2138.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1150, NULL, 144, 49, '2025-08-29', '2025-08-31', 'Checked-Out', 21384.00, 10.00, 0.00, 0.00, 'Cash', 4276.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1152, NULL, 14, 49, '2025-09-06', '2025-09-11', 'Checked-Out', 21384.00, 10.00, 0.00, 0.00, 'Card', 10692.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1153, NULL, 113, 49, '2025-09-13', '2025-09-18', 'Checked-Out', 21384.00, 10.00, 0.00, 0.00, 'Online', 10692.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1154, NULL, 125, 49, '2025-09-19', '2025-09-21', 'Checked-Out', 21384.00, 10.00, 0.00, 0.00, 'Online', 4276.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1156, NULL, 102, 49, '2025-09-29', '2025-10-03', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Online', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1159, NULL, 26, 50, '2025-07-10', '2025-07-14', 'Checked-In', 18000.00, 10.00, 0.00, 0.00, 'Online', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1160, NULL, 125, 50, '2025-07-15', '2025-07-17', 'Checked-In', 18000.00, 10.00, 0.00, 0.00, 'Online', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1163, NULL, 122, 50, '2025-07-25', '2025-07-27', 'Checked-Out', 19440.00, 10.00, 0.00, 0.00, 'Cash', 3888.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1164, NULL, 40, 50, '2025-07-27', '2025-07-29', 'Checked-In', 18000.00, 10.00, 0.00, 0.00, 'Online', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1165, NULL, 86, 50, '2025-07-30', '2025-08-01', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Cash', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1168, NULL, 127, 50, '2025-08-11', '2025-08-13', 'Checked-In', 19800.00, 10.00, 0.00, 0.00, 'Cash', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1169, NULL, 20, 50, '2025-08-15', '2025-08-19', 'Checked-Out', 21384.00, 10.00, 0.00, 0.00, 'Online', 8553.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1171, NULL, 29, 50, '2025-08-26', '2025-08-30', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Card', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1172, NULL, 42, 50, '2025-08-31', '2025-09-03', 'Checked-In', 19800.00, 10.00, 0.00, 0.00, 'Online', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1173, NULL, 86, 50, '2025-09-03', '2025-09-05', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Card', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1174, NULL, 58, 50, '2025-09-05', '2025-09-09', 'Checked-In', 21384.00, 10.00, 0.00, 0.00, 'Card', 8553.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1176, NULL, 50, 50, '2025-09-14', '2025-09-19', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Online', 9900.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1177, NULL, 102, 50, '2025-09-20', '2025-09-21', 'Checked-Out', 21384.00, 10.00, 0.00, 0.00, 'Online', 2138.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1178, NULL, 28, 50, '2025-09-22', '2025-09-24', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Online', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1179, NULL, 130, 50, '2025-09-25', '2025-09-28', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'BankTransfer', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1180, NULL, 107, 50, '2025-09-29', '2025-10-04', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Online', 9900.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1182, NULL, 8, 51, '2025-07-04', '2025-07-06', 'Checked-Out', 19440.00, 10.00, 0.00, 0.00, 'Card', 3888.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1183, NULL, 121, 51, '2025-07-07', '2025-07-11', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Card', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1446, NULL, 1, 1, '2025-11-15', '2025-11-17', 'Booked', 20000.00, 0.00, 0.00, 0.00, NULL, 10000.00, DEFAULT, '2025-10-07 19:14:43.849846+05:30');
INSERT INTO public.booking VALUES (1305, NULL, 149, 56, '2025-07-21', '2025-07-26', 'Cancelled', 12000.00, 10.00, 0.00, 0.00, 'Cash', 6000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1349, NULL, 93, 58, '2025-07-24', '2025-07-28', 'Checked-Out', 12000.00, 10.00, 935.25, 0.00, 'Card', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1375, NULL, 74, 59, '2025-08-10', '2025-08-14', 'Checked-Out', 13200.00, 10.00, 1538.92, 0.00, 'BankTransfer', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1303, NULL, 19, 56, '2025-07-16', '2025-07-18', 'Checked-Out', 12000.00, 10.00, 1474.03, 0.00, 'Card', 2400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1324, NULL, 56, 57, '2025-07-15', '2025-07-20', 'Checked-Out', 12000.00, 10.00, 1474.03, 0.00, 'Online', 6000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1327, NULL, 22, 57, '2025-07-31', '2025-08-02', 'Checked-Out', 12000.00, 10.00, 1474.03, 0.00, 'Cash', 2400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1353, NULL, 105, 58, '2025-08-09', '2025-08-13', 'Checked-Out', 14256.00, 10.00, 1751.15, 0.00, 'BankTransfer', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1373, NULL, 103, 59, '2025-08-02', '2025-08-05', 'Checked-Out', 14256.00, 10.00, 1751.15, 0.00, 'BankTransfer', 4276.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1355, NULL, 57, 58, '2025-08-17', '2025-08-22', 'Checked-Out', 13200.00, 10.00, 0.00, 3169.84, 'BankTransfer', 6600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1315, NULL, 20, 56, '2025-09-08', '2025-09-11', 'Cancelled', 13200.00, 10.00, 0.00, 0.00, 'Cash', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1184, NULL, 76, 51, '2025-07-13', '2025-07-14', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Card', 1800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1185, NULL, 33, 51, '2025-07-15', '2025-07-20', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Cash', 9000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1186, NULL, 112, 51, '2025-07-20', '2025-07-24', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Card', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1187, NULL, 46, 51, '2025-07-25', '2025-07-27', 'Checked-Out', 19440.00, 10.00, 0.00, 0.00, 'BankTransfer', 3888.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1188, NULL, 14, 51, '2025-07-29', '2025-07-30', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Cash', 1800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1189, NULL, 25, 51, '2025-07-31', '2025-08-04', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Card', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1191, NULL, 51, 51, '2025-08-06', '2025-08-10', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Cash', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1193, NULL, 129, 51, '2025-08-17', '2025-08-19', 'Checked-In', 19800.00, 10.00, 0.00, 0.00, 'BankTransfer', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1196, NULL, 92, 51, '2025-08-28', '2025-08-31', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'BankTransfer', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1197, NULL, 143, 51, '2025-08-31', '2025-09-04', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Online', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1199, NULL, 96, 51, '2025-09-09', '2025-09-12', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Online', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1201, NULL, 25, 51, '2025-09-15', '2025-09-17', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Online', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1203, NULL, 91, 51, '2025-09-22', '2025-09-27', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Card', 9900.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1204, NULL, 57, 51, '2025-09-29', '2025-10-03', 'Checked-In', 19800.00, 10.00, 0.00, 0.00, 'Online', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1205, NULL, 68, 52, '2025-07-01', '2025-07-02', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'BankTransfer', 1800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1206, NULL, 105, 52, '2025-07-04', '2025-07-08', 'Checked-Out', 19440.00, 10.00, 0.00, 0.00, 'Cash', 7776.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1207, NULL, 40, 52, '2025-07-09', '2025-07-13', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Online', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1210, NULL, 58, 52, '2025-07-25', '2025-07-28', 'Checked-In', 19440.00, 10.00, 0.00, 0.00, 'BankTransfer', 5832.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1214, NULL, 91, 52, '2025-08-07', '2025-08-10', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Online', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1217, NULL, 144, 52, '2025-08-17', '2025-08-19', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Cash', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1218, NULL, 37, 52, '2025-08-19', '2025-08-23', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'BankTransfer', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1219, NULL, 96, 52, '2025-08-23', '2025-08-25', 'Checked-Out', 21384.00, 10.00, 0.00, 0.00, 'Card', 4276.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1220, NULL, 144, 52, '2025-08-25', '2025-08-26', 'Checked-In', 19800.00, 10.00, 0.00, 0.00, 'Online', 1980.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1149, NULL, 35, 49, '2025-08-24', '2025-08-28', 'Checked-Out', 19800.00, 10.00, 2067.87, 0.00, 'Cash', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1161, NULL, 21, 50, '2025-07-17', '2025-07-21', 'Checked-In', 18000.00, 10.00, 2686.99, 0.00, 'BankTransfer', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1194, NULL, 114, 51, '2025-08-20', '2025-08-22', 'Checked-In', 19800.00, 10.00, 2044.43, 0.00, 'Cash', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1215, NULL, 86, 52, '2025-08-11', '2025-08-13', 'Cancelled', 19800.00, 10.00, 3517.32, 0.00, 'BankTransfer', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1155, NULL, 70, 49, '2025-09-22', '2025-09-27', 'Checked-Out', 19800.00, 10.00, 2432.15, 0.00, 'Online', 9900.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1141, NULL, 85, 49, '2025-07-28', '2025-07-31', 'Checked-Out', 18000.00, 10.00, 0.00, 3827.56, 'Online', 5400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1151, NULL, 10, 49, '2025-09-01', '2025-09-04', 'Checked-Out', 19800.00, 10.00, 1656.65, 0.00, 'Cash', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1157, NULL, 140, 50, '2025-07-01', '2025-07-05', 'Checked-Out', 18000.00, 10.00, 2526.14, 0.00, 'Cash', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1166, NULL, 10, 50, '2025-08-01', '2025-08-05', 'Checked-In', 21384.00, 10.00, 1306.01, 0.00, 'Card', 8553.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1175, NULL, 96, 50, '2025-09-09', '2025-09-12', 'Checked-In', 19800.00, 10.00, 3572.19, 0.00, 'BankTransfer', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1211, NULL, 140, 52, '2025-07-28', '2025-07-30', 'Checked-Out', 18000.00, 10.00, 2919.66, 0.00, 'Online', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1158, NULL, 142, 50, '2025-07-06', '2025-07-09', 'Checked-In', 18000.00, 10.00, 2211.05, 0.00, 'Online', 5400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1170, NULL, 136, 50, '2025-08-19', '2025-08-24', 'Checked-Out', 19800.00, 10.00, 2432.15, 0.00, 'Card', 9900.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1202, NULL, 47, 51, '2025-09-18', '2025-09-21', 'Checked-Out', 19800.00, 10.00, 2432.15, 0.00, 'Online', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1209, NULL, 100, 52, '2025-07-19', '2025-07-23', 'Checked-In', 19440.00, 10.00, 2387.93, 0.00, 'BankTransfer', 7776.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1195, NULL, 5, 51, '2025-08-23', '2025-08-27', 'Checked-Out', 21384.00, 10.00, 2626.72, 0.00, 'BankTransfer', 8553.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1143, NULL, 52, 49, '2025-08-05', '2025-08-07', 'Checked-Out', 19800.00, 10.00, 0.00, 2516.61, 'Cash', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1144, NULL, 66, 49, '2025-08-07', '2025-08-09', 'Checked-Out', 19800.00, 10.00, 0.00, 3442.70, 'Cash', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1181, NULL, 22, 51, '2025-07-01', '2025-07-03', 'Checked-In', 18000.00, 10.00, 0.00, 2860.50, 'Online', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1212, NULL, 4, 52, '2025-07-30', '2025-08-01', 'Checked-Out', 18000.00, 10.00, 0.00, 3902.18, 'BankTransfer', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1216, NULL, 63, 52, '2025-08-14', '2025-08-17', 'Checked-Out', 19800.00, 10.00, 0.00, 4384.10, 'Online', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1223, NULL, 26, 52, '2025-09-03', '2025-09-07', 'Checked-In', 19800.00, 10.00, 0.00, 0.00, 'Cash', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1224, NULL, 54, 52, '2025-09-07', '2025-09-11', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Online', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1225, NULL, 121, 52, '2025-09-13', '2025-09-17', 'Checked-In', 21384.00, 10.00, 0.00, 0.00, 'Online', 8553.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (501, NULL, 20, 22, '2025-07-30', '2025-08-01', 'Cancelled', 40000.00, 10.00, 4855.34, 0.00, 'Card', 8000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1386, NULL, 45, 59, '2025-09-30', '2025-10-01', 'Checked-In', 13200.00, 10.00, 1621.43, 0.00, 'Online', 1320.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1387, NULL, 81, 60, '2025-07-01', '2025-07-04', 'Checked-In', 12000.00, 10.00, 1015.33, 0.00, 'Cash', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1408, NULL, 80, 60, '2025-09-24', '2025-09-25', 'Checked-In', 13200.00, 10.00, 2440.15, 0.00, 'Card', 1320.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1, NULL, 1, 1, '2025-07-01', '2025-07-05', 'Checked-Out', 40000.00, 10.00, 4618.14, 0.00, 'Cash', 16000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (156, NULL, 116, 7, '2025-08-16', '2025-08-19', 'Checked-Out', 28512.00, 10.00, 3560.26, 0.00, 'Online', 8553.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (198, NULL, 34, 9, '2025-08-01', '2025-08-05', 'Checked-Out', 21384.00, 10.00, 2146.77, 0.00, 'Online', 8553.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (234, NULL, 1, 10, '2025-09-18', '2025-09-21', 'Checked-Out', 19800.00, 10.00, 2432.15, 0.00, 'Cash', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (952, NULL, 89, 41, '2025-07-27', '2025-07-28', 'Checked-Out', 40000.00, 10.00, 6557.48, 0.00, 'Cash', 4000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1226, NULL, 92, 52, '2025-09-18', '2025-09-19', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Cash', 1980.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1227, NULL, 65, 52, '2025-09-19', '2025-09-23', 'Checked-Out', 21384.00, 10.00, 0.00, 0.00, 'Cash', 8553.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1228, NULL, 65, 52, '2025-09-23', '2025-09-27', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Cash', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1230, NULL, 137, 53, '2025-07-01', '2025-07-03', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Cash', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1231, NULL, 106, 53, '2025-07-05', '2025-07-08', 'Checked-Out', 19440.00, 10.00, 0.00, 0.00, 'BankTransfer', 5832.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1232, NULL, 88, 53, '2025-07-10', '2025-07-13', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Online', 5400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1233, NULL, 144, 53, '2025-07-15', '2025-07-19', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Cash', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1234, NULL, 43, 53, '2025-07-20', '2025-07-23', 'Checked-In', 18000.00, 10.00, 0.00, 0.00, 'Card', 5400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1238, NULL, 108, 53, '2025-08-05', '2025-08-09', 'Checked-In', 19800.00, 10.00, 0.00, 0.00, 'Online', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1240, NULL, 83, 53, '2025-08-17', '2025-08-21', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'BankTransfer', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1242, NULL, 125, 53, '2025-08-25', '2025-08-29', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Card', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1247, NULL, 76, 53, '2025-09-19', '2025-09-22', 'Checked-In', 21384.00, 10.00, 0.00, 0.00, 'Cash', 6415.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1248, NULL, 8, 53, '2025-09-24', '2025-09-27', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Online', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1253, NULL, 94, 54, '2025-07-12', '2025-07-13', 'Checked-Out', 19440.00, 10.00, 0.00, 0.00, 'Cash', 1944.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1254, NULL, 142, 54, '2025-07-14', '2025-07-18', 'Checked-In', 18000.00, 10.00, 0.00, 0.00, 'Cash', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1255, NULL, 136, 54, '2025-07-18', '2025-07-22', 'Checked-Out', 19440.00, 10.00, 0.00, 0.00, 'Card', 7776.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1256, NULL, 50, 54, '2025-07-22', '2025-07-25', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Cash', 5400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1257, NULL, 139, 54, '2025-07-26', '2025-07-30', 'Checked-Out', 19440.00, 10.00, 0.00, 0.00, 'Online', 7776.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1258, NULL, 9, 54, '2025-07-31', '2025-08-04', 'Checked-In', 18000.00, 10.00, 0.00, 0.00, 'BankTransfer', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1263, NULL, 10, 54, '2025-08-22', '2025-08-23', 'Checked-Out', 21384.00, 10.00, 0.00, 0.00, 'BankTransfer', 2138.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1267, NULL, 126, 54, '2025-09-02', '2025-09-06', 'Checked-In', 19800.00, 10.00, 0.00, 0.00, 'Cash', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1268, NULL, 57, 54, '2025-09-08', '2025-09-12', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Cash', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1270, NULL, 23, 54, '2025-09-16', '2025-09-17', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Online', 1980.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1272, NULL, 136, 54, '2025-09-20', '2025-09-24', 'Checked-Out', 21384.00, 10.00, 0.00, 0.00, 'Card', 8553.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1274, NULL, 102, 54, '2025-09-30', '2025-10-04', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Cash', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1275, NULL, 105, 55, '2025-07-01', '2025-07-03', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'BankTransfer', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1277, NULL, 102, 55, '2025-07-07', '2025-07-11', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'BankTransfer', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1278, NULL, 19, 55, '2025-07-11', '2025-07-15', 'Checked-Out', 19440.00, 10.00, 0.00, 0.00, 'Card', 7776.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1280, NULL, 12, 55, '2025-07-21', '2025-07-25', 'Checked-Out', 18000.00, 10.00, 0.00, 0.00, 'Card', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1281, NULL, 52, 55, '2025-07-25', '2025-07-26', 'Checked-Out', 19440.00, 10.00, 0.00, 0.00, 'Cash', 1944.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1283, NULL, 113, 55, '2025-08-01', '2025-08-04', 'Checked-Out', 21384.00, 10.00, 0.00, 0.00, 'Cash', 6415.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1285, NULL, 88, 55, '2025-08-08', '2025-08-12', 'Checked-Out', 21384.00, 10.00, 0.00, 0.00, 'Cash', 8553.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1286, NULL, 15, 55, '2025-08-14', '2025-08-19', 'Checked-In', 19800.00, 10.00, 0.00, 0.00, 'Cash', 9900.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1288, NULL, 84, 55, '2025-08-23', '2025-08-28', 'Checked-Out', 21384.00, 10.00, 0.00, 0.00, 'Cash', 10692.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1289, NULL, 132, 55, '2025-08-28', '2025-08-31', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Card', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1291, NULL, 45, 55, '2025-09-04', '2025-09-05', 'Checked-In', 19800.00, 10.00, 0.00, 0.00, 'Cash', 1980.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1292, NULL, 58, 55, '2025-09-06', '2025-09-08', 'Checked-Out', 21384.00, 10.00, 0.00, 0.00, 'BankTransfer', 4276.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1293, NULL, 131, 55, '2025-09-10', '2025-09-14', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Online', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1296, NULL, 63, 55, '2025-09-21', '2025-09-23', 'Checked-In', 19800.00, 10.00, 0.00, 0.00, 'Online', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1297, NULL, 109, 55, '2025-09-25', '2025-09-28', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'BankTransfer', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1298, NULL, 24, 55, '2025-09-29', '2025-10-04', 'Checked-Out', 19800.00, 10.00, 0.00, 0.00, 'Cash', 9900.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1252, NULL, 93, 54, '2025-07-09', '2025-07-10', 'Checked-Out', 18000.00, 10.00, 3133.10, 0.00, 'BankTransfer', 1800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1260, NULL, 81, 54, '2025-08-11', '2025-08-15', 'Checked-Out', 19800.00, 10.00, 2197.31, 0.00, 'Cash', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1237, NULL, 91, 53, '2025-08-02', '2025-08-03', 'Checked-Out', 21384.00, 10.00, 0.00, 2228.93, 'Cash', 2138.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1265, NULL, 113, 54, '2025-08-26', '2025-08-28', 'Checked-Out', 19800.00, 10.00, 3035.50, 0.00, 'Online', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1266, NULL, 96, 54, '2025-08-29', '2025-09-01', 'Checked-Out', 21384.00, 10.00, 3721.60, 0.00, 'Cash', 6415.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1271, NULL, 80, 54, '2025-09-18', '2025-09-19', 'Checked-Out', 19800.00, 10.00, 3679.94, 0.00, 'Online', 1980.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1222, NULL, 29, 52, '2025-08-30', '2025-09-01', 'Checked-Out', 21384.00, 10.00, 2626.72, 0.00, 'Cash', 4276.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1245, NULL, 58, 53, '2025-09-08', '2025-09-10', 'Checked-Out', 19800.00, 10.00, 2432.15, 0.00, 'Cash', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1284, NULL, 66, 55, '2025-08-04', '2025-08-07', 'Checked-Out', 19800.00, 10.00, 2432.15, 0.00, 'Cash', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1251, NULL, 86, 54, '2025-07-04', '2025-07-08', 'Checked-In', 19440.00, 10.00, 2142.83, 0.00, 'Online', 7776.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (605, NULL, 36, 26, '2025-09-03', '2025-09-04', 'Checked-Out', 26400.00, 10.00, 3242.87, 0.00, 'BankTransfer', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (666, NULL, 55, 29, '2025-07-16', '2025-07-18', 'Checked-In', 18000.00, 10.00, 2211.05, 0.00, 'Cash', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (746, NULL, 101, 32, '2025-09-07', '2025-09-11', 'Checked-Out', 19800.00, 10.00, 2432.15, 0.00, 'Card', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1295, NULL, 91, 55, '2025-09-19', '2025-09-21', 'Checked-In', 21384.00, 10.00, 2626.72, 0.00, 'BankTransfer', 4276.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1261, NULL, 58, 54, '2025-08-17', '2025-08-18', 'Checked-Out', 19800.00, 10.00, 2432.15, 0.00, 'Cash', 1980.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1239, NULL, 138, 53, '2025-08-11', '2025-08-16', 'Cancelled', 19800.00, 10.00, 0.00, 0.00, 'Card', 9900.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1244, NULL, 82, 53, '2025-09-05', '2025-09-07', 'Cancelled', 21384.00, 10.00, 0.00, 0.00, 'Online', 4276.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1249, NULL, 116, 53, '2025-09-27', '2025-10-01', 'Cancelled', 21384.00, 10.00, 0.00, 0.00, 'Cash', 8553.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1250, NULL, 150, 54, '2025-07-01', '2025-07-03', 'Cancelled', 18000.00, 10.00, 0.00, 0.00, 'Online', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1246, NULL, 81, 53, '2025-09-12', '2025-09-17', 'Cancelled', 21384.00, 10.00, 1086.57, 0.00, 'Cash', 10692.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1269, NULL, 82, 54, '2025-09-13', '2025-09-15', 'Checked-In', 21384.00, 10.00, 0.00, 3109.19, 'Online', 4276.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1273, NULL, 31, 54, '2025-09-25', '2025-09-29', 'Checked-Out', 19800.00, 10.00, 0.00, 2887.03, 'Cash', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1276, NULL, 55, 55, '2025-07-05', '2025-07-07', 'Checked-Out', 19440.00, 10.00, 0.00, 4267.62, 'Online', 3888.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1302, NULL, 22, 56, '2025-07-10', '2025-07-14', 'Checked-Out', 12000.00, 10.00, 0.00, 1994.07, 'BankTransfer', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1241, NULL, 78, 53, '2025-08-23', '2025-08-25', 'Checked-Out', 21384.00, 10.00, 2626.72, 2875.72, 'Online', 4276.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1304, NULL, 90, 56, '2025-07-19', '2025-07-20', 'Checked-Out', 12960.00, 10.00, 0.00, 0.00, 'Online', 1296.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1307, NULL, 129, 56, '2025-07-31', '2025-08-02', 'Checked-Out', 12000.00, 10.00, 0.00, 0.00, 'Card', 2400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1309, NULL, 68, 56, '2025-08-06', '2025-08-09', 'Checked-In', 13200.00, 10.00, 0.00, 0.00, 'Card', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1310, NULL, 125, 56, '2025-08-10', '2025-08-15', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Cash', 6600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1311, NULL, 82, 56, '2025-08-16', '2025-08-20', 'Checked-Out', 14256.00, 10.00, 0.00, 0.00, 'BankTransfer', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1312, NULL, 39, 56, '2025-08-21', '2025-08-26', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Cash', 6600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1313, NULL, 63, 56, '2025-08-28', '2025-09-01', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Cash', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1314, NULL, 80, 56, '2025-09-03', '2025-09-07', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Online', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1317, NULL, 123, 56, '2025-09-16', '2025-09-21', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Online', 6600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1318, NULL, 16, 56, '2025-09-21', '2025-09-24', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Online', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1319, NULL, 58, 56, '2025-09-26', '2025-09-30', 'Checked-Out', 14256.00, 10.00, 0.00, 0.00, 'Card', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1321, NULL, 89, 57, '2025-07-01', '2025-07-05', 'Checked-In', 12000.00, 10.00, 0.00, 0.00, 'Online', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1322, NULL, 112, 57, '2025-07-07', '2025-07-10', 'Checked-Out', 12000.00, 10.00, 0.00, 0.00, 'Online', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1323, NULL, 98, 57, '2025-07-11', '2025-07-13', 'Checked-Out', 12960.00, 10.00, 0.00, 0.00, 'Online', 2592.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1325, NULL, 19, 57, '2025-07-22', '2025-07-26', 'Checked-Out', 12000.00, 10.00, 0.00, 0.00, 'Cash', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1326, NULL, 91, 57, '2025-07-26', '2025-07-30', 'Checked-In', 12960.00, 10.00, 0.00, 0.00, 'Card', 5184.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1328, NULL, 21, 57, '2025-08-02', '2025-08-06', 'Checked-In', 14256.00, 10.00, 0.00, 0.00, 'Card', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1329, NULL, 133, 57, '2025-08-07', '2025-08-09', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Online', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1330, NULL, 22, 57, '2025-08-10', '2025-08-15', 'Checked-In', 13200.00, 10.00, 0.00, 0.00, 'Card', 6600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1332, NULL, 142, 57, '2025-08-20', '2025-08-24', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Cash', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1335, NULL, 79, 57, '2025-08-31', '2025-09-02', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Online', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1337, NULL, 145, 57, '2025-09-08', '2025-09-13', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'BankTransfer', 6600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1338, NULL, 80, 57, '2025-09-15', '2025-09-18', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Cash', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1341, NULL, 80, 57, '2025-09-26', '2025-09-28', 'Checked-In', 14256.00, 10.00, 0.00, 0.00, 'Online', 2851.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1342, NULL, 150, 57, '2025-09-30', '2025-10-04', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'BankTransfer', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1343, NULL, 99, 58, '2025-07-01', '2025-07-05', 'Checked-Out', 12000.00, 10.00, 0.00, 0.00, 'Cash', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1344, NULL, 50, 58, '2025-07-05', '2025-07-07', 'Checked-Out', 12960.00, 10.00, 0.00, 0.00, 'Card', 2592.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1345, NULL, 31, 58, '2025-07-08', '2025-07-13', 'Checked-Out', 12000.00, 10.00, 0.00, 0.00, 'BankTransfer', 6000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1348, NULL, 101, 58, '2025-07-20', '2025-07-23', 'Checked-Out', 12000.00, 10.00, 0.00, 0.00, 'Cash', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1351, NULL, 107, 58, '2025-08-02', '2025-08-04', 'Checked-Out', 14256.00, 10.00, 0.00, 0.00, 'Cash', 2851.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1356, NULL, 39, 58, '2025-08-23', '2025-08-27', 'Checked-Out', 14256.00, 10.00, 0.00, 0.00, 'Online', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1357, NULL, 54, 58, '2025-08-27', '2025-09-01', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Card', 6600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1362, NULL, 102, 58, '2025-09-22', '2025-09-24', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Online', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1363, NULL, 28, 58, '2025-09-25', '2025-09-29', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Cash', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1364, NULL, 101, 58, '2025-09-29', '2025-10-04', 'Checked-In', 13200.00, 10.00, 0.00, 0.00, 'Cash', 6600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1365, NULL, 144, 59, '2025-07-01', '2025-07-03', 'Checked-Out', 12000.00, 10.00, 0.00, 0.00, 'Cash', 2400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1367, NULL, 36, 59, '2025-07-11', '2025-07-13', 'Checked-Out', 12960.00, 10.00, 0.00, 0.00, 'Card', 2592.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1368, NULL, 32, 59, '2025-07-13', '2025-07-16', 'Checked-Out', 12000.00, 10.00, 0.00, 0.00, 'Online', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1370, NULL, 66, 59, '2025-07-22', '2025-07-25', 'Checked-Out', 12000.00, 10.00, 0.00, 0.00, 'Online', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1371, NULL, 100, 59, '2025-07-27', '2025-07-30', 'Checked-In', 12000.00, 10.00, 0.00, 0.00, 'Online', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1374, NULL, 126, 59, '2025-08-06', '2025-08-08', 'Checked-In', 13200.00, 10.00, 0.00, 0.00, 'Cash', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1376, NULL, 116, 59, '2025-08-15', '2025-08-17', 'Checked-Out', 14256.00, 10.00, 0.00, 0.00, 'Card', 2851.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1378, NULL, 37, 59, '2025-08-22', '2025-08-25', 'Checked-Out', 14256.00, 10.00, 0.00, 0.00, 'Online', 4276.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1379, NULL, 147, 59, '2025-08-26', '2025-08-30', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Online', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1380, NULL, 56, 59, '2025-09-01', '2025-09-04', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Online', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1381, NULL, 16, 59, '2025-09-06', '2025-09-10', 'Checked-Out', 14256.00, 10.00, 0.00, 0.00, 'Online', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1383, NULL, 50, 59, '2025-09-14', '2025-09-19', 'Checked-In', 13200.00, 10.00, 0.00, 0.00, 'BankTransfer', 6600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1333, NULL, 50, 57, '2025-08-24', '2025-08-27', 'Checked-Out', 13200.00, 10.00, 1052.17, 0.00, 'Card', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1449, NULL, 1, 5, '2025-11-10', '2025-11-12', 'Checked-In', 20000.00, 0.00, 0.00, 0.00, NULL, 10000.00, DEFAULT, '2025-10-07 19:31:12.65907+05:30');
INSERT INTO public.booking VALUES (1425, NULL, 125, 47, '2025-10-08', '2025-10-12', 'Booked', 24000.00, 10.00, 2948.06, 0.00, 'Card', 9600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (284, NULL, 29, 12, '2025-09-25', '2025-09-29', 'Checked-Out', 19800.00, 10.00, 3755.52, 0.00, 'Online', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (606, NULL, 48, 26, '2025-09-05', '2025-09-08', 'Checked-Out', 28512.00, 10.00, 2340.32, 0.00, 'Cash', 8553.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (124, NULL, 90, 6, '2025-07-30', '2025-07-31', 'Checked-Out', 24000.00, 10.00, 2948.06, 0.00, 'Online', 2400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (128, NULL, 128, 6, '2025-08-08', '2025-08-12', 'Checked-Out', 28512.00, 10.00, 3502.30, 0.00, 'Cash', 11404.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (136, NULL, 111, 6, '2025-09-07', '2025-09-09', 'Checked-Out', 26400.00, 10.00, 3242.87, 0.00, 'BankTransfer', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (325, NULL, 7, 14, '2025-09-20', '2025-09-25', 'Checked-Out', 21384.00, 10.00, 2626.72, 0.00, 'Online', 10692.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (814, NULL, 10, 35, '2025-08-18', '2025-08-20', 'Checked-Out', 19800.00, 10.00, 2432.15, 0.00, 'Online', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1120, NULL, 72, 48, '2025-08-11', '2025-08-12', 'Checked-Out', 26400.00, 10.00, 3242.87, 0.00, 'Card', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1294, NULL, 121, 55, '2025-09-15', '2025-09-18', 'Cancelled', 19800.00, 10.00, 3905.19, 0.00, 'Cash', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (326, NULL, 42, 14, '2025-09-25', '2025-09-29', 'Cancelled', 19800.00, 10.00, 2012.20, 0.00, 'Cash', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1118, NULL, 113, 48, '2025-08-03', '2025-08-08', 'Cancelled', 26400.00, 10.00, 3277.92, 0.00, 'Online', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1125, NULL, 7, 48, '2025-08-27', '2025-08-29', 'Cancelled', 26400.00, 10.00, 3642.93, 0.00, 'Online', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1377, NULL, 117, 59, '2025-08-18', '2025-08-21', 'Cancelled', 13200.00, 10.00, 1229.24, 0.00, 'Online', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1279, NULL, 3, 55, '2025-07-16', '2025-07-19', 'Checked-Out', 18000.00, 10.00, 3120.70, 2418.27, 'Online', 5400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (301, NULL, 109, 13, '2025-09-03', '2025-09-05', 'Checked-In', 19800.00, 10.00, 3361.08, 2814.18, 'BankTransfer', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (725, NULL, 70, 31, '2025-09-19', '2025-09-24', 'Checked-Out', 21384.00, 10.00, 2073.10, 2842.46, 'Card', 10692.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1016, NULL, 143, 44, '2025-07-21', '2025-07-26', 'Checked-Out', 24000.00, 10.00, 2948.06, 4324.16, 'Online', 12000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1128, NULL, 137, 48, '2025-09-08', '2025-09-10', 'Checked-Out', 26400.00, 10.00, 3242.87, 0.00, 'Cash', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1299, NULL, 146, 56, '2025-07-01', '2025-07-04', 'Checked-Out', 12000.00, 10.00, 1474.03, 0.00, 'Online', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (565, NULL, 36, 24, '2025-09-19', '2025-09-24', 'Checked-Out', 28512.00, 10.00, 3502.30, 0.00, 'BankTransfer', 14256.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (237, NULL, 42, 10, '2025-09-29', '2025-10-03', 'Checked-Out', 19800.00, 10.00, 2432.15, 0.00, 'Cash', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (243, NULL, 71, 11, '2025-07-23', '2025-07-26', 'Checked-Out', 18000.00, 10.00, 2211.05, 0.00, 'Card', 5400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (848, NULL, 72, 36, '2025-09-20', '2025-09-22', 'Cancelled', 14256.00, 10.00, 1703.31, 0.00, 'Online', 2851.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (104, NULL, 57, 5, '2025-08-10', '2025-08-15', 'Cancelled', 26400.00, 10.00, 3242.87, 0.00, 'Online', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (189, NULL, 46, 8, '2025-09-27', '2025-09-29', 'Checked-Out', 28512.00, 10.00, 3502.30, 6346.62, 'Online', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (233, NULL, 82, 10, '2025-09-13', '2025-09-16', 'Checked-Out', 21384.00, 10.00, 2626.72, 6266.21, 'Cash', 6415.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (805, NULL, 78, 35, '2025-07-15', '2025-07-18', 'Checked-In', 18000.00, 10.00, 0.00, 2116.82, 'BankTransfer', 5400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (811, NULL, 96, 35, '2025-08-06', '2025-08-07', 'Checked-Out', 19800.00, 10.00, 0.00, 3780.20, 'Cash', 1980.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (742, NULL, 5, 32, '2025-08-24', '2025-08-26', 'Checked-Out', 19800.00, 10.00, 3434.93, 4267.08, 'Card', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (734, NULL, 145, 32, '2025-07-25', '2025-07-28', 'Checked-Out', 19440.00, 10.00, 2387.93, 5651.67, 'Cash', 5832.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1350, NULL, 82, 58, '2025-07-29', '2025-08-02', 'Checked-Out', 12000.00, 10.00, 0.00, 1477.79, 'Online', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1336, NULL, 125, 57, '2025-09-03', '2025-09-07', 'Checked-Out', 13200.00, 10.00, 2243.80, 0.00, 'Card', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1354, NULL, 19, 58, '2025-08-14', '2025-08-15', 'Checked-Out', 13200.00, 10.00, 2293.53, 0.00, 'BankTransfer', 1320.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1358, NULL, 13, 58, '2025-09-03', '2025-09-08', 'Checked-Out', 13200.00, 10.00, 1747.78, 0.00, 'Online', 6600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1361, NULL, 139, 58, '2025-09-17', '2025-09-21', 'Checked-Out', 13200.00, 10.00, 1304.07, 0.00, 'Cash', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1340, NULL, 134, 57, '2025-09-21', '2025-09-25', 'Checked-Out', 13200.00, 10.00, 1428.55, 0.00, 'Cash', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1346, NULL, 57, 58, '2025-07-14', '2025-07-17', 'Checked-Out', 12000.00, 10.00, 1043.39, 0.00, 'Online', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1331, NULL, 147, 57, '2025-08-15', '2025-08-19', 'Cancelled', 14256.00, 10.00, 0.00, 0.00, 'Cash', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1359, NULL, 132, 58, '2025-09-10', '2025-09-14', 'Cancelled', 13200.00, 10.00, 0.00, 0.00, 'Card', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1334, NULL, 64, 57, '2025-08-29', '2025-08-31', 'Cancelled', 14256.00, 10.00, 1554.23, 0.00, 'Cash', 2851.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1347, NULL, 24, 58, '2025-07-17', '2025-07-19', 'Cancelled', 12000.00, 10.00, 1474.03, 0.00, 'Online', 2400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1360, NULL, 126, 58, '2025-09-14', '2025-09-16', 'Checked-Out', 13200.00, 10.00, 814.52, 3833.99, 'Card', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1384, NULL, 7, 59, '2025-09-21', '2025-09-25', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Card', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1389, NULL, 100, 60, '2025-07-10', '2025-07-12', 'Checked-Out', 12000.00, 10.00, 0.00, 0.00, 'Card', 2400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1391, NULL, 72, 60, '2025-07-18', '2025-07-20', 'Checked-Out', 12960.00, 10.00, 0.00, 0.00, 'Cash', 2592.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1393, NULL, 129, 60, '2025-07-27', '2025-07-31', 'Checked-In', 12000.00, 10.00, 0.00, 0.00, 'Card', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1394, NULL, 14, 60, '2025-08-01', '2025-08-02', 'Checked-In', 14256.00, 10.00, 0.00, 0.00, 'Cash', 1425.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1395, NULL, 8, 60, '2025-08-02', '2025-08-06', 'Checked-Out', 14256.00, 10.00, 0.00, 0.00, 'BankTransfer', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1396, NULL, 7, 60, '2025-08-07', '2025-08-10', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Online', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1397, NULL, 32, 60, '2025-08-12', '2025-08-14', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Cash', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1399, NULL, 148, 60, '2025-08-19', '2025-08-23', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Online', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1400, NULL, 53, 60, '2025-08-24', '2025-08-26', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Cash', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1401, NULL, 128, 60, '2025-08-28', '2025-08-30', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Card', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1402, NULL, 73, 60, '2025-08-31', '2025-09-04', 'Checked-In', 13200.00, 10.00, 0.00, 0.00, 'Cash', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1404, NULL, 69, 60, '2025-09-07', '2025-09-12', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Cash', 6600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1407, NULL, 34, 60, '2025-09-21', '2025-09-22', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'Card', 1320.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1409, NULL, 15, 60, '2025-09-26', '2025-09-29', 'Checked-Out', 14256.00, 10.00, 0.00, 0.00, 'BankTransfer', 4276.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1410, NULL, 38, 60, '2025-09-30', '2025-10-01', 'Checked-Out', 13200.00, 10.00, 0.00, 0.00, 'BankTransfer', 1320.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (15, NULL, 75, 1, '2025-08-31', '2025-09-04', 'Checked-Out', 44000.00, 10.00, 3411.77, 0.00, 'Cash', 17600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (20, NULL, 58, 1, '2025-09-23', '2025-09-26', 'Checked-Out', 44000.00, 10.00, 3795.87, 0.00, 'Cash', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (52, NULL, 86, 3, '2025-07-20', '2025-07-22', 'Checked-In', 40000.00, 10.00, 3521.68, 0.00, 'Cash', 8000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (66, NULL, 38, 3, '2025-09-15', '2025-09-19', 'Checked-Out', 44000.00, 10.00, 7126.80, 0.00, 'Card', 17600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (76, NULL, 20, 4, '2025-07-18', '2025-07-20', 'Checked-Out', 25920.00, 10.00, 2940.11, 0.00, 'Card', 5184.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (78, NULL, 48, 4, '2025-07-25', '2025-07-29', 'Checked-Out', 25920.00, 10.00, 4684.90, 0.00, 'Cash', 10368.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (83, NULL, 106, 4, '2025-08-17', '2025-08-19', 'Checked-In', 26400.00, 10.00, 2039.90, 0.00, 'BankTransfer', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (121, NULL, 44, 6, '2025-07-14', '2025-07-16', 'Checked-Out', 24000.00, 10.00, 3244.33, 0.00, 'BankTransfer', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (126, NULL, 115, 6, '2025-08-02', '2025-08-05', 'Checked-Out', 28512.00, 10.00, 1772.79, 0.00, 'BankTransfer', 8553.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (127, NULL, 40, 6, '2025-08-05', '2025-08-08', 'Checked-Out', 26400.00, 10.00, 3581.45, 0.00, 'Cash', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (129, NULL, 118, 6, '2025-08-14', '2025-08-17', 'Checked-Out', 26400.00, 10.00, 4855.41, 0.00, 'Cash', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (138, NULL, 139, 6, '2025-09-12', '2025-09-13', 'Checked-Out', 28512.00, 10.00, 1792.05, 0.00, 'Online', 2851.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (163, NULL, 100, 7, '2025-09-18', '2025-09-22', 'Checked-Out', 26400.00, 10.00, 1395.52, 0.00, 'Online', 10560.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (185, NULL, 141, 8, '2025-09-09', '2025-09-14', 'Checked-Out', 26400.00, 10.00, 2548.44, 0.00, 'Online', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (217, NULL, 24, 10, '2025-07-26', '2025-07-30', 'Checked-Out', 19440.00, 10.00, 3052.92, 0.00, 'Online', 7776.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (232, NULL, 1, 10, '2025-09-11', '2025-09-12', 'Checked-Out', 19800.00, 10.00, 1105.69, 0.00, 'Cash', 1980.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (238, NULL, 93, 11, '2025-07-01', '2025-07-06', 'Checked-Out', 18000.00, 10.00, 2130.36, 0.00, 'Online', 9000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (239, NULL, 83, 11, '2025-07-06', '2025-07-07', 'Checked-Out', 18000.00, 10.00, 1593.77, 0.00, 'Cash', 1800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (254, NULL, 20, 11, '2025-08-30', '2025-09-03', 'Checked-Out', 21384.00, 10.00, 2499.81, 0.00, 'Online', 8553.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (270, NULL, 32, 12, '2025-08-02', '2025-08-05', 'Checked-Out', 21384.00, 10.00, 1862.47, 0.00, 'Online', 6415.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (294, NULL, 86, 13, '2025-08-04', '2025-08-08', 'Checked-Out', 19800.00, 10.00, 1267.24, 0.00, 'Online', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (327, NULL, 65, 14, '2025-09-29', '2025-10-03', 'Checked-Out', 19800.00, 10.00, 3160.27, 0.00, 'Online', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (361, NULL, 117, 16, '2025-07-29', '2025-07-31', 'Checked-Out', 12000.00, 10.00, 1066.28, 0.00, 'Online', 2400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (365, NULL, 81, 16, '2025-08-12', '2025-08-14', 'Checked-Out', 13200.00, 10.00, 2058.00, 0.00, 'BankTransfer', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (405, NULL, 105, 18, '2025-07-14', '2025-07-19', 'Checked-Out', 12000.00, 10.00, 2319.10, 0.00, 'Card', 6000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (435, NULL, 31, 19, '2025-08-09', '2025-08-12', 'Checked-Out', 14256.00, 10.00, 1850.88, 0.00, 'BankTransfer', 4276.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (438, NULL, 45, 19, '2025-08-18', '2025-08-21', 'Checked-Out', 13200.00, 10.00, 1884.39, 0.00, 'Card', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (462, NULL, 59, 20, '2025-08-20', '2025-08-23', 'Checked-In', 13200.00, 10.00, 1163.33, 0.00, 'Online', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1388, NULL, 11, 60, '2025-07-05', '2025-07-09', 'Checked-Out', 12960.00, 10.00, 1855.27, 0.00, 'Cash', 5184.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (339, NULL, 66, 15, '2025-08-10', '2025-08-11', 'Cancelled', 19800.00, 10.00, 1364.69, 0.00, 'Online', 1980.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1392, NULL, 102, 60, '2025-07-21', '2025-07-26', 'Checked-Out', 12000.00, 10.00, 1474.03, 0.00, 'BankTransfer', 6000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (50, NULL, 141, 3, '2025-07-12', '2025-07-15', 'Checked-In', 43200.00, 10.00, 5306.51, 0.00, 'Card', 12960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (312, NULL, 115, 14, '2025-07-21', '2025-07-26', 'Checked-In', 18000.00, 10.00, 1371.61, 3634.37, 'Cash', 9000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (225, NULL, 120, 10, '2025-08-20', '2025-08-22', 'Checked-In', 19800.00, 10.00, 2432.15, 4017.04, 'Online', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (488, NULL, 148, 21, '2025-09-09', '2025-09-13', 'Checked-Out', 44000.00, 10.00, 3990.92, 0.00, 'BankTransfer', 17600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (495, NULL, 124, 22, '2025-07-04', '2025-07-09', 'Checked-In', 43200.00, 10.00, 4830.19, 0.00, 'BankTransfer', 21600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (506, NULL, 32, 22, '2025-08-20', '2025-08-24', 'Checked-Out', 44000.00, 10.00, 7944.81, 0.00, 'Card', 17600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (517, NULL, 113, 22, '2025-09-30', '2025-10-04', 'Checked-Out', 44000.00, 10.00, 2861.81, 0.00, 'Online', 17600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (527, NULL, 18, 23, '2025-08-02', '2025-08-06', 'Checked-Out', 47520.00, 10.00, 6118.21, 0.00, 'Online', 19008.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (548, NULL, 49, 24, '2025-07-17', '2025-07-18', 'Checked-Out', 24000.00, 10.00, 3327.15, 0.00, 'BankTransfer', 2400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (549, NULL, 69, 24, '2025-07-19', '2025-07-20', 'Checked-Out', 25920.00, 10.00, 2894.49, 0.00, 'BankTransfer', 2592.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (560, NULL, 18, 24, '2025-08-30', '2025-08-31', 'Checked-Out', 28512.00, 10.00, 2753.80, 0.00, 'Cash', 2851.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (574, NULL, 92, 25, '2025-07-24', '2025-07-28', 'Checked-Out', 24000.00, 10.00, 3375.05, 0.00, 'Card', 9600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (587, NULL, 57, 25, '2025-09-17', '2025-09-20', 'Checked-Out', 26400.00, 10.00, 5277.77, 0.00, 'Cash', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (595, NULL, 146, 26, '2025-07-16', '2025-07-21', 'Checked-Out', 24000.00, 10.00, 2014.17, 0.00, 'Cash', 12000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (604, NULL, 150, 26, '2025-08-31', '2025-09-02', 'Checked-Out', 26400.00, 10.00, 1501.22, 0.00, 'Cash', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (615, NULL, 130, 27, '2025-07-08', '2025-07-10', 'Checked-In', 24000.00, 10.00, 4443.87, 0.00, 'Cash', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (644, NULL, 4, 28, '2025-08-01', '2025-08-02', 'Checked-In', 28512.00, 10.00, 2080.68, 0.00, 'Online', 2851.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (726, NULL, 85, 31, '2025-09-26', '2025-09-30', 'Checked-In', 21384.00, 10.00, 3909.41, 0.00, 'Online', 8553.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (730, NULL, 121, 32, '2025-07-13', '2025-07-14', 'Checked-Out', 18000.00, 10.00, 3008.12, 0.00, 'Card', 1800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (732, NULL, 35, 32, '2025-07-19', '2025-07-20', 'Checked-In', 19440.00, 10.00, 3653.59, 0.00, 'Card', 1944.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (733, NULL, 141, 32, '2025-07-21', '2025-07-23', 'Checked-Out', 18000.00, 10.00, 2980.77, 0.00, 'Card', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (758, NULL, 133, 33, '2025-08-04', '2025-08-06', 'Checked-Out', 19800.00, 10.00, 1617.87, 0.00, 'Online', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (770, NULL, 60, 33, '2025-09-21', '2025-09-26', 'Checked-Out', 19800.00, 10.00, 2759.36, 0.00, 'Cash', 9900.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (812, NULL, 119, 35, '2025-08-09', '2025-08-12', 'Checked-Out', 21384.00, 10.00, 2772.59, 0.00, 'Cash', 6415.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (859, NULL, 1, 37, '2025-07-29', '2025-08-03', 'Checked-Out', 12000.00, 10.00, 1253.52, 0.00, 'Card', 6000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (891, NULL, 138, 38, '2025-08-22', '2025-08-24', 'Checked-Out', 14256.00, 10.00, 2760.80, 0.00, 'Online', 2851.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (896, NULL, 1, 38, '2025-09-12', '2025-09-15', 'Checked-Out', 14256.00, 10.00, 2158.01, 0.00, 'Cash', 4276.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (929, NULL, 97, 40, '2025-07-27', '2025-07-30', 'Checked-Out', 12000.00, 10.00, 2323.12, 0.00, 'Cash', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (932, NULL, 27, 40, '2025-08-08', '2025-08-09', 'Checked-In', 14256.00, 10.00, 1526.52, 0.00, 'Online', 1425.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (940, NULL, 147, 40, '2025-09-11', '2025-09-13', 'Checked-Out', 13200.00, 10.00, 1366.39, 0.00, 'Cash', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (973, NULL, 144, 42, '2025-07-22', '2025-07-24', 'Checked-Out', 40000.00, 10.00, 4410.37, 0.00, 'BankTransfer', 8000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (974, NULL, 48, 42, '2025-07-25', '2025-07-29', 'Checked-Out', 43200.00, 10.00, 2857.03, 0.00, 'Online', 17280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (984, NULL, 150, 42, '2025-09-10', '2025-09-15', 'Checked-Out', 44000.00, 10.00, 6772.85, 0.00, 'Online', 22000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (996, NULL, 145, 43, '2025-07-27', '2025-07-31', 'Checked-Out', 40000.00, 10.00, 7685.29, 0.00, 'Online', 16000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1005, NULL, 25, 43, '2025-09-05', '2025-09-10', 'Checked-Out', 47520.00, 10.00, 3841.77, 0.00, 'Cash', 23760.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1006, NULL, 132, 43, '2025-09-10', '2025-09-12', 'Checked-Out', 44000.00, 10.00, 6051.20, 0.00, 'Online', 8800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1025, NULL, 92, 44, '2025-08-29', '2025-09-01', 'Checked-Out', 28512.00, 10.00, 5006.86, 0.00, 'Online', 8553.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1031, NULL, 99, 44, '2025-09-19', '2025-09-21', 'Checked-Out', 28512.00, 10.00, 5520.36, 0.00, 'Online', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1038, NULL, 85, 45, '2025-07-16', '2025-07-17', 'Checked-Out', 24000.00, 10.00, 3453.13, 0.00, 'Cash', 2400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1053, NULL, 120, 45, '2025-09-05', '2025-09-09', 'Checked-In', 28512.00, 10.00, 3929.82, 0.00, 'Cash', 11404.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1094, NULL, 71, 47, '2025-08-05', '2025-08-08', 'Checked-Out', 26400.00, 10.00, 4550.75, 0.00, 'Cash', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1162, NULL, 95, 50, '2025-07-23', '2025-07-24', 'Checked-In', 18000.00, 10.00, 3144.20, 0.00, 'Cash', 1800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1167, NULL, 125, 50, '2025-08-05', '2025-08-10', 'Checked-In', 19800.00, 10.00, 1788.35, 0.00, 'Cash', 9900.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1190, NULL, 147, 51, '2025-08-05', '2025-08-06', 'Checked-In', 19800.00, 10.00, 2623.92, 0.00, 'BankTransfer', 1980.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1198, NULL, 14, 51, '2025-09-04', '2025-09-07', 'Checked-Out', 19800.00, 10.00, 2379.98, 0.00, 'Cash', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1200, NULL, 119, 51, '2025-09-14', '2025-09-15', 'Checked-In', 19800.00, 10.00, 2692.43, 0.00, 'Online', 1980.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1208, NULL, 138, 52, '2025-07-14', '2025-07-18', 'Checked-In', 18000.00, 10.00, 3148.88, 0.00, 'Online', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (553, NULL, 39, 24, '2025-08-02', '2025-08-06', 'Checked-Out', 28512.00, 10.00, 5676.40, 0.00, 'Cash', 11404.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (685, NULL, 149, 29, '2025-09-28', '2025-10-01', 'Checked-Out', 19800.00, 10.00, 3057.96, 0.00, 'Card', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (907, NULL, 30, 39, '2025-07-26', '2025-07-31', 'Checked-Out', 12960.00, 10.00, 2150.14, 0.00, 'Cash', 6480.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1192, NULL, 144, 51, '2025-08-12', '2025-08-16', 'Checked-Out', 19800.00, 10.00, 3725.04, 0.00, 'Online', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1243, NULL, 142, 53, '2025-08-30', '2025-09-03', 'Checked-Out', 21384.00, 10.00, 2527.00, 0.00, 'Card', 8553.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (763, NULL, 34, 33, '2025-08-30', '2025-08-31', 'Checked-Out', 21384.00, 10.00, 2626.72, 0.00, 'Cash', 2138.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (829, NULL, 101, 36, '2025-07-09', '2025-07-11', 'Checked-Out', 12000.00, 10.00, 1474.03, 0.00, 'Cash', 2400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (834, NULL, 124, 36, '2025-07-25', '2025-07-26', 'Checked-In', 12960.00, 10.00, 1591.95, 0.00, 'Online', 1296.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (993, NULL, 79, 43, '2025-07-15', '2025-07-18', 'Checked-Out', 40000.00, 10.00, 4913.43, 0.00, 'BankTransfer', 12000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (593, NULL, 65, 26, '2025-07-06', '2025-07-10', 'Checked-Out', 24000.00, 10.00, 3099.94, 6426.01, 'BankTransfer', 9600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (623, NULL, 103, 27, '2025-08-09', '2025-08-14', 'Checked-In', 28512.00, 10.00, 4555.36, 4335.29, 'Cash', 14256.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (956, NULL, 16, 41, '2025-08-12', '2025-08-16', 'Checked-Out', 44000.00, 10.00, 2353.91, 7443.93, 'Cash', 17600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (754, NULL, 16, 33, '2025-07-12', '2025-07-17', 'Checked-Out', 19440.00, 10.00, 2387.93, 3467.87, 'Cash', 9720.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (785, NULL, 133, 34, '2025-08-04', '2025-08-05', 'Checked-Out', 19800.00, 10.00, 2432.15, 2427.68, 'Online', 1980.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1259, NULL, 2, 54, '2025-08-05', '2025-08-09', 'Checked-Out', 19800.00, 10.00, 1474.94, 0.00, 'Cash', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1262, NULL, 104, 54, '2025-08-18', '2025-08-20', 'Checked-Out', 19800.00, 10.00, 3349.97, 0.00, 'Online', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1264, NULL, 137, 54, '2025-08-23', '2025-08-25', 'Checked-Out', 21384.00, 10.00, 3589.62, 0.00, 'Online', 4276.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1282, NULL, 137, 55, '2025-07-27', '2025-07-31', 'Checked-Out', 18000.00, 10.00, 2002.00, 0.00, 'Cash', 7200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1287, NULL, 85, 55, '2025-08-20', '2025-08-22', 'Checked-Out', 19800.00, 10.00, 2178.58, 0.00, 'Card', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1290, NULL, 34, 55, '2025-08-31', '2025-09-03', 'Checked-Out', 19800.00, 10.00, 3459.11, 0.00, 'Card', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1300, NULL, 50, 56, '2025-07-04', '2025-07-07', 'Checked-Out', 12960.00, 10.00, 1129.23, 0.00, 'BankTransfer', 3888.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1308, NULL, 77, 56, '2025-08-03', '2025-08-06', 'Checked-Out', 13200.00, 10.00, 867.39, 0.00, 'Cash', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1316, NULL, 93, 56, '2025-09-12', '2025-09-14', 'Checked-In', 14256.00, 10.00, 2222.37, 0.00, 'BankTransfer', 2851.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1339, NULL, 130, 57, '2025-09-18', '2025-09-20', 'Checked-Out', 13200.00, 10.00, 1311.99, 0.00, 'Card', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1352, NULL, 9, 58, '2025-08-05', '2025-08-07', 'Checked-Out', 13200.00, 10.00, 850.14, 0.00, 'Online', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1372, NULL, 124, 59, '2025-08-01', '2025-08-02', 'Checked-Out', 14256.00, 10.00, 2405.31, 0.00, 'Cash', 1425.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1382, NULL, 22, 59, '2025-09-12', '2025-09-14', 'Checked-Out', 14256.00, 10.00, 1597.66, 0.00, 'Cash', 2851.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1403, NULL, 96, 60, '2025-09-05', '2025-09-07', 'Checked-In', 14256.00, 10.00, 2080.27, 0.00, 'Online', 2851.20, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1405, NULL, 40, 60, '2025-09-13', '2025-09-14', 'Checked-Out', 14256.00, 10.00, 1199.50, 0.00, 'Online', 1425.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (459, NULL, 142, 20, '2025-08-09', '2025-08-13', 'Checked-Out', 14256.00, 10.00, 1280.98, 0.00, 'Cash', 5702.40, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (477, NULL, 77, 21, '2025-07-17', '2025-07-19', 'Checked-Out', 40000.00, 10.00, 7374.06, 0.00, 'Cash', 8000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (486, NULL, 77, 21, '2025-08-29', '2025-09-01', 'Checked-In', 47520.00, 10.00, 7235.23, 0.00, 'BankTransfer', 14256.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (489, NULL, 44, 21, '2025-09-13', '2025-09-16', 'Checked-Out', 47520.00, 10.00, 5278.17, 0.00, 'Cash', 14256.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (675, NULL, 6, 29, '2025-08-17', '2025-08-21', 'Checked-In', 19800.00, 10.00, 3777.28, 0.00, 'Online', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (846, NULL, 116, 36, '2025-09-11', '2025-09-16', 'Checked-Out', 13200.00, 10.00, 2294.05, 0.00, 'Cash', 6600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (853, NULL, 147, 37, '2025-07-05', '2025-07-08', 'Checked-In', 12960.00, 10.00, 2194.13, 0.00, 'Cash', 3888.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (152, NULL, 89, 7, '2025-08-05', '2025-08-10', 'Checked-Out', 26400.00, 10.00, 1427.69, 0.00, 'Card', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1453, NULL, 1, 20, '2025-11-12', '2025-11-14', 'Booked', 20000.00, 0.00, 0.00, 0.00, NULL, 5000.00, DEFAULT, '2025-10-07 20:12:53.650944+05:30');
INSERT INTO public.booking VALUES (1457, NULL, 1, 20, '2025-11-14', '2025-11-16', 'Booked', 20000.00, 0.00, 0.00, 0.00, NULL, 4000.00, DEFAULT, '2025-10-07 20:13:50.131468+05:30');
INSERT INTO public.booking VALUES (1458, NULL, 1, 20, '2025-11-16', '2025-11-18', 'Booked', 20000.00, 0.00, 0.00, 0.00, NULL, 4000.00, DEFAULT, '2025-10-07 20:19:55.782881+05:30');
INSERT INTO public.booking VALUES (1406, NULL, 91, 60, '2025-09-15', '2025-09-20', 'Checked-In', 13200.00, 10.00, 1926.90, 0.00, 'Cash', 6600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (63, NULL, 89, 3, '2025-09-03', '2025-09-05', 'Checked-Out', 44000.00, 10.00, 2862.76, 0.00, 'BankTransfer', 8800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (64, NULL, 18, 3, '2025-09-06', '2025-09-10', 'Checked-Out', 47520.00, 10.00, 5905.57, 0.00, 'Cash', 19008.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (164, NULL, 67, 7, '2025-09-23', '2025-09-25', 'Checked-Out', 26400.00, 10.00, 2128.99, 0.00, 'Cash', 5280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (300, NULL, 29, 13, '2025-08-30', '2025-09-01', 'Checked-Out', 21384.00, 10.00, 1510.63, 0.00, 'Cash', 4276.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (304, NULL, 101, 13, '2025-09-16', '2025-09-21', 'Checked-Out', 19800.00, 10.00, 3300.09, 0.00, 'Card', 9900.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (314, NULL, 136, 14, '2025-07-31', '2025-08-05', 'Checked-Out', 18000.00, 10.00, 3337.14, 0.00, 'Card', 9000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (383, NULL, 141, 17, '2025-07-15', '2025-07-18', 'Checked-In', 12000.00, 10.00, 1702.10, 0.00, 'Card', 3600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (396, NULL, 108, 17, '2025-09-13', '2025-09-14', 'Checked-Out', 14256.00, 10.00, 2429.15, 0.00, 'BankTransfer', 1425.60, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (463, NULL, 45, 20, '2025-08-24', '2025-08-29', 'Checked-Out', 13200.00, 10.00, 760.05, 0.00, 'Online', 6600.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (550, NULL, 145, 24, '2025-07-22', '2025-07-24', 'Checked-Out', 24000.00, 10.00, 1592.54, 0.00, 'Cash', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (888, NULL, 118, 38, '2025-08-12', '2025-08-15', 'Checked-Out', 13200.00, 10.00, 1610.23, 0.00, 'BankTransfer', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1115, NULL, 82, 48, '2025-07-24', '2025-07-25', 'Checked-Out', 24000.00, 10.00, 2550.50, 0.00, 'BankTransfer', 2400.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1132, NULL, 74, 48, '2025-09-21', '2025-09-22', 'Checked-Out', 26400.00, 10.00, 1911.92, 0.00, 'Cash', 2640.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1134, NULL, 55, 48, '2025-09-29', '2025-10-02', 'Checked-Out', 26400.00, 10.00, 2493.03, 0.00, 'Online', 7920.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1366, NULL, 65, 59, '2025-07-05', '2025-07-09', 'Checked-Out', 12960.00, 10.00, 1461.77, 0.00, 'BankTransfer', 5184.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1369, NULL, 104, 59, '2025-07-17', '2025-07-21', 'Checked-Out', 12000.00, 10.00, 1556.79, 0.00, 'Online', 4800.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (25, NULL, 118, 2, '2025-07-12', '2025-07-16', 'Checked-Out', 43200.00, 10.00, 2503.28, 0.00, 'Card', 17280.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (34, NULL, 53, 2, '2025-08-13', '2025-08-16', 'Checked-Out', 44000.00, 10.00, 4984.25, 0.00, 'Cash', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (436, NULL, 101, 19, '2025-08-12', '2025-08-13', 'Checked-In', 13200.00, 10.00, 1339.87, 0.00, 'Card', 1320.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (635, NULL, 129, 27, '2025-09-24', '2025-09-29', 'Checked-Out', 26400.00, 10.00, 4404.89, 0.00, 'Cash', 13200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (717, NULL, 57, 31, '2025-08-11', '2025-08-14', 'Checked-Out', 19800.00, 10.00, 1993.01, 0.00, 'Cash', 5940.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (911, NULL, 60, 39, '2025-08-12', '2025-08-15', 'Checked-Out', 13200.00, 10.00, 1199.94, 0.00, 'Online', 3960.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1002, NULL, 111, 43, '2025-08-23', '2025-08-27', 'Checked-In', 47520.00, 10.00, 3484.10, 0.00, 'Cash', 19008.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1014, NULL, 7, 44, '2025-07-10', '2025-07-15', 'Checked-Out', 24000.00, 10.00, 2299.07, 0.00, 'Cash', 12000.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1027, NULL, 86, 44, '2025-09-06', '2025-09-10', 'Checked-In', 28512.00, 10.00, 1553.67, 0.00, 'Cash', 11404.80, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1235, NULL, 144, 53, '2025-07-25', '2025-07-27', 'Checked-Out', 19440.00, 10.00, 3188.56, 0.00, 'Cash', 3888.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (1301, NULL, 64, 56, '2025-07-07', '2025-07-08', 'Checked-In', 12000.00, 10.00, 1406.54, 0.00, 'Card', 1200.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (210, NULL, 103, 9, '2025-09-25', '2025-09-30', 'Checked-Out', 19800.00, 10.00, 1072.20, 0.00, 'BankTransfer', 9900.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');
INSERT INTO public.booking VALUES (442, NULL, 124, 19, '2025-08-30', '2025-09-04', 'Checked-Out', 14256.00, 10.00, 1396.48, 0.00, 'Cash', 7128.00, DEFAULT, '2025-10-06 23:33:18.829019+05:30');


--
-- TOC entry 5391 (class 0 OID 16389)
-- Dependencies: 219
-- Data for Name: branch; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.branch VALUES (1, 'Colombo', '011-236-1234', 'No. 1 Galle Road, Kollupitiya, Colombo 03', 'N. Silva', 'COL');
INSERT INTO public.branch VALUES (2, 'Kandy', '081-223-4567', '38, Temple Street, Kandy', 'S. Perera', 'KAN');
INSERT INTO public.branch VALUES (3, 'Galle', '091-224-7890', '12, Lighthouse Ave, Galle Fort, Galle', 'D. Fernando', 'GAL');


--
-- TOC entry 5407 (class 0 OID 16519)
-- Dependencies: 235
-- Data for Name: customer; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.customer VALUES (1, 5, 1, '2025-10-05 15:02:36.044053+05:30');
INSERT INTO public.customer VALUES (2, 6, 7, '2025-10-05 15:02:36.044053+05:30');
INSERT INTO public.customer VALUES (3, 7, 14, '2025-10-05 15:02:36.044053+05:30');
INSERT INTO public.customer VALUES (4, 8, 27, '2025-10-05 15:02:36.044053+05:30');
INSERT INTO public.customer VALUES (5, 9, 33, '2025-10-05 15:02:36.044053+05:30');
INSERT INTO public.customer VALUES (6, 10, 37, '2025-10-05 15:02:36.044053+05:30');
INSERT INTO public.customer VALUES (7, 11, 39, '2025-10-05 15:02:36.044053+05:30');
INSERT INTO public.customer VALUES (8, 12, 40, '2025-10-05 15:02:36.044053+05:30');
INSERT INTO public.customer VALUES (9, 13, 52, '2025-10-05 15:02:36.044053+05:30');
INSERT INTO public.customer VALUES (10, 14, 56, '2025-10-05 15:02:36.044053+05:30');
INSERT INTO public.customer VALUES (11, 15, 57, '2025-10-05 15:02:36.044053+05:30');
INSERT INTO public.customer VALUES (12, 16, 65, '2025-10-05 15:02:36.044053+05:30');
INSERT INTO public.customer VALUES (13, 17, 72, '2025-10-05 15:02:36.044053+05:30');
INSERT INTO public.customer VALUES (14, 18, 76, '2025-10-05 15:02:36.044053+05:30');
INSERT INTO public.customer VALUES (15, 19, 82, '2025-10-05 15:02:36.044053+05:30');
INSERT INTO public.customer VALUES (16, 20, 83, '2025-10-05 15:02:36.044053+05:30');
INSERT INTO public.customer VALUES (17, 21, 95, '2025-10-05 15:02:36.044053+05:30');
INSERT INTO public.customer VALUES (18, 22, 97, '2025-10-05 15:02:36.044053+05:30');
INSERT INTO public.customer VALUES (19, 23, 104, '2025-10-05 15:02:36.044053+05:30');
INSERT INTO public.customer VALUES (20, 24, 106, '2025-10-05 15:02:36.044053+05:30');
INSERT INTO public.customer VALUES (21, 25, 111, '2025-10-05 15:02:36.044053+05:30');
INSERT INTO public.customer VALUES (22, 26, 116, '2025-10-05 15:02:36.044053+05:30');
INSERT INTO public.customer VALUES (23, 27, 118, '2025-10-05 15:02:36.044053+05:30');
INSERT INTO public.customer VALUES (24, 28, 132, '2025-10-05 15:02:36.044053+05:30');
INSERT INTO public.customer VALUES (25, 29, 139, '2025-10-05 15:02:36.044053+05:30');


--
-- TOC entry 5405 (class 0 OID 16508)
-- Dependencies: 233
-- Data for Name: employee; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.employee VALUES (7, 42, 1, 'Manager Colombo', 'manager_colombo@skynest.com', '0605379521');
INSERT INTO public.employee VALUES (8, 43, 2, 'Manager Kandy', 'manager_kandy@skynest.com', '0299773942');
INSERT INTO public.employee VALUES (9, 44, 3, 'Manager Galle', 'manager_galle@skynest.com', '0808175988');
INSERT INTO public.employee VALUES (10, 45, 1, 'Recept Colombo', 'recept_colombo@skynest.com', '0764460531');
INSERT INTO public.employee VALUES (11, 46, 2, 'Recept Kandy', 'recept_kandy@skynest.com', '0343942921');
INSERT INTO public.employee VALUES (12, 47, 3, 'Recept Galle', 'recept_galle@skynest.com', '0751293513');
INSERT INTO public.employee VALUES (13, 48, 1, 'Accountant Colombo', 'accountant_colombo@skynest.com', '0935540724');
INSERT INTO public.employee VALUES (14, 49, 2, 'Accountant Kandy', 'accountant_kandy@skynest.com', '0261705604');
INSERT INTO public.employee VALUES (15, 50, 3, 'Accountant Galle', 'accountant_galle@skynest.com', '0734487693');


--
-- TOC entry 5401 (class 0 OID 16484)
-- Dependencies: 229
-- Data for Name: guest; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.guest VALUES (1, '700000001V', 'Ishara Wickramasinghe', 'ishara.wickramasinghe1@example.com', '072-6111617', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (2, '700000002V', 'Nadeesha Abeysekera', 'nadeesha.abeysekera2@example.com', '077-3862809', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (3, '700000003V', 'Bhanuka Peiris', 'bhanuka.peiris3@example.com', '078-0642602', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (4, '700000004V', 'Nuwan Bandara', 'nuwan.bandara4@example.com', '078-0199525', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (5, '700000005V', 'Tharindu Jayasinghe', 'tharindu.jayasinghe5@example.com', '078-4568005', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (6, '700000006V', 'Ayesha Ranasinghe', 'ayesha.ranasinghe6@example.com', '074-6369236', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (7, '700000007V', 'Nuwan Peiris', 'nuwan.peiris7@example.com', '071-8131247', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (8, '700000008V', 'Sachini Peiris', 'sachini.peiris8@example.com', '072-3458606', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (9, '700000009V', 'Malith Wijesinghe', 'malith.wijesinghe9@example.com', '073-3848861', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (10, '700000010V', 'Harini Perera', 'harini.perera10@example.com', '076-4417421', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (11, '700000011V', 'Maneesha Peiris', 'maneesha.peiris11@example.com', '071-6127680', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (12, '700000012V', 'Pramudi Perera', 'pramudi.perera12@example.com', '077-7898841', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (13, '700000013V', 'Maneesha Wijesinghe', 'maneesha.wijesinghe13@example.com', '074-0444887', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (14, '700000014V', 'Ayesha Bandara', 'ayesha.bandara14@example.com', '075-0625147', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (15, '700000015V', 'Roshan Perera', 'roshan.perera15@example.com', '074-7049978', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (16, '700000016V', 'Ishara Fernando', 'ishara.fernando16@example.com', '071-3444405', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (17, '700000017V', 'Bhanuka Perera', 'bhanuka.perera17@example.com', '072-7902099', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (18, '700000018V', 'Dinuka Jayasinghe', 'dinuka.jayasinghe18@example.com', '071-6491447', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (19, '700000019V', 'Harini Wickramasinghe', 'harini.wickramasinghe19@example.com', '072-2512118', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (20, '700000020V', 'Bhanuka Silva', 'bhanuka.silva20@example.com', '078-3896233', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (21, '700000021V', 'Dulani Peiris', 'dulani.peiris21@example.com', '075-0716788', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (22, '700000022V', 'Chamath Bandara', 'chamath.bandara22@example.com', '077-6289248', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (23, '700000023V', 'Chamath Peiris', 'chamath.peiris23@example.com', '074-8864345', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (24, '700000024V', 'Maneesha Gunasekara', 'maneesha.gunasekara24@example.com', '071-8978168', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (25, '700000025V', 'Nadeesha Fernando', 'nadeesha.fernando25@example.com', '077-5230318', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (26, '700000026V', 'Sachini Karunaratne', 'sachini.karunaratne26@example.com', '074-9190926', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (27, '700000027V', 'Kasun Jayasinghe', 'kasun.jayasinghe27@example.com', '071-0887659', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (28, '700000028V', 'Nimal Abeysekera', 'nimal.abeysekera28@example.com', '077-3292255', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (29, '700000029V', 'Kavindu Abeysekera', 'kavindu.abeysekera29@example.com', '076-6352676', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (30, '700000030V', 'Lakmini Wickramasinghe', 'lakmini.wickramasinghe30@example.com', '075-6731176', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (31, '700000031V', 'Sachini Ranasinghe', 'sachini.ranasinghe31@example.com', '073-4012689', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (32, '700000032V', 'Nuwan Ranasinghe', 'nuwan.ranasinghe32@example.com', '074-9833776', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (33, '700000033V', 'Roshan Peiris', 'roshan.peiris33@example.com', '072-9296200', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (34, '700000034V', 'Malith Ekanayake', 'malith.ekanayake34@example.com', '077-9230454', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (35, '700000035V', 'Lakmini Weerasinghe', 'lakmini.weerasinghe35@example.com', '077-8319123', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (36, '700000036V', 'Dinuka Fernando', 'dinuka.fernando36@example.com', '072-4982723', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (37, '700000037V', 'Kavindu Wijesinghe', 'kavindu.wijesinghe37@example.com', '075-8727855', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (38, '700000038V', 'Sanduni Gunasekara', 'sanduni.gunasekara38@example.com', '074-1771443', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (39, '700000039V', 'Kavindu Ranasinghe', 'kavindu.ranasinghe39@example.com', '071-7768346', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (40, '700000040V', 'Supun Fernando', 'supun.fernando40@example.com', '072-1392584', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (41, '700000041V', 'Pramudi Fernando', 'pramudi.fernando41@example.com', '073-3756844', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (42, '700000042V', 'Chathura Karunaratne', 'chathura.karunaratne42@example.com', '075-6970848', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (43, '700000043V', 'Dinuka Silva', 'dinuka.silva43@example.com', '073-9020758', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (44, '700000044V', 'Maneesha Bandara', 'maneesha.bandara44@example.com', '077-4300393', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (45, '700000045V', 'Pramudi Silva', 'pramudi.silva45@example.com', '073-8990372', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (46, '700000046V', 'Ruwan Ranasinghe', 'ruwan.ranasinghe46@example.com', '077-1106828', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (47, '700000047V', 'Sanduni Silva', 'sanduni.silva47@example.com', '072-4474953', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (48, '700000048V', 'Sajith Ranasinghe', 'sajith.ranasinghe48@example.com', '071-6839948', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (49, '700000049V', 'Chamath Abeysekera', 'chamath.abeysekera49@example.com', '072-7230963', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (50, '700000050V', 'Dulani Jayasinghe', 'dulani.jayasinghe50@example.com', '073-6857193', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (51, '700000051V', 'Shenal Perera', 'shenal.perera51@example.com', '072-2375825', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (52, '700000052V', 'Hasini Karunaratne', 'hasini.karunaratne52@example.com', '078-4623101', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (53, '700000053V', 'Tharindu Weerasinghe', 'tharindu.weerasinghe53@example.com', '073-4246350', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (54, '700000054V', 'Malith Abeysekera', 'malith.abeysekera54@example.com', '073-9929454', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (55, '700000055V', 'Nuwan Jayasinghe', 'nuwan.jayasinghe55@example.com', '076-3914467', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (56, '700000056V', 'Ishara Weerasinghe', 'ishara.weerasinghe56@example.com', '076-7836495', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (57, '700000057V', 'Maneesha Fernando', 'maneesha.fernando57@example.com', '075-0511688', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (58, '700000058V', 'Chamath Ekanayake', 'chamath.ekanayake58@example.com', '074-7854520', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (59, '700000059V', 'Roshan Wijesinghe', 'roshan.wijesinghe59@example.com', '076-8258014', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (60, '700000060V', 'Ayesha Peiris', 'ayesha.peiris60@example.com', '075-6326572', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (61, '700000061V', 'Thisara Abeysekera', 'thisara.abeysekera61@example.com', '077-8513260', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (62, '700000062V', 'Shenal Fernando', 'shenal.fernando62@example.com', '077-1117659', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (63, '700000063V', 'Ayesha Silva', 'ayesha.silva63@example.com', '075-0871460', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (64, '700000064V', 'Nimal Silva', 'nimal.silva64@example.com', '077-8005969', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (65, '700000065V', 'Shenal Gunasekara', 'shenal.gunasekara65@example.com', '075-0892574', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (66, '700000066V', 'Bhanuka Ranasinghe', 'bhanuka.ranasinghe66@example.com', '076-3178336', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (67, '700000067V', 'Kasun Ranasinghe', 'kasun.ranasinghe67@example.com', '076-8187023', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (68, '700000068V', 'Maneesha Jayasinghe', 'maneesha.jayasinghe68@example.com', '076-9650382', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (69, '700000069V', 'Chamath Ranasinghe', 'chamath.ranasinghe69@example.com', '071-3897528', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (70, '700000070V', 'Thisara Fernando', 'thisara.fernando70@example.com', '074-0156296', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (71, '700000071V', 'Nuwan Peiris', 'nuwan.peiris71@example.com', '076-7345482', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (72, '700000072V', 'Ishani Jayasinghe', 'ishani.jayasinghe72@example.com', '076-7490544', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (73, '700000073V', 'Pasindu Weerasinghe', 'pasindu.weerasinghe73@example.com', '078-6904699', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (74, '700000074V', 'Nuwan Wijesinghe', 'nuwan.wijesinghe74@example.com', '071-1760566', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (75, '700000075V', 'Shenal Ranasinghe', 'shenal.ranasinghe75@example.com', '071-2735496', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (76, '700000076V', 'Dulani Abeysekera', 'dulani.abeysekera76@example.com', '078-2875830', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (77, '700000077V', 'Roshan Gunasekara', 'roshan.gunasekara77@example.com', '073-4317972', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (78, '700000078V', 'Harini Wickramasinghe', 'harini.wickramasinghe78@example.com', '073-1837352', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (79, '700000079V', 'Malith Ranasinghe', 'malith.ranasinghe79@example.com', '077-2085172', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (80, '700000080V', 'Tharindu Karunaratne', 'tharindu.karunaratne80@example.com', '071-0672868', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (81, '700000081V', 'Chathura Wijesinghe', 'chathura.wijesinghe81@example.com', '077-2714987', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (82, '700000082V', 'Dulani Gunasekara', 'dulani.gunasekara82@example.com', '076-3983765', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (83, '700000083V', 'Ishani Ranasinghe', 'ishani.ranasinghe83@example.com', '077-0521359', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (84, '700000084V', 'Nadeesha Abeysekera', 'nadeesha.abeysekera84@example.com', '076-9415793', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (85, '700000085V', 'Bhanuka Wickramasinghe', 'bhanuka.wickramasinghe85@example.com', '072-3532273', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (86, '700000086V', 'Lakmini Ekanayake', 'lakmini.ekanayake86@example.com', '077-1553244', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (87, '700000087V', 'Nimal Peiris', 'nimal.peiris87@example.com', '078-5773136', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (88, '700000088V', 'Nimal Perera', 'nimal.perera88@example.com', '077-3371763', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (89, '700000089V', 'Roshan Jayasinghe', 'roshan.jayasinghe89@example.com', '071-3703308', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (90, '700000090V', 'Nuwan Abeysekera', 'nuwan.abeysekera90@example.com', '076-7884506', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (91, '700000091V', 'Malith Bandara', 'malith.bandara91@example.com', '072-8425297', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (92, '700000092V', 'Kavindu Ranasinghe', 'kavindu.ranasinghe92@example.com', '074-0948805', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (93, '700000093V', 'Hasini Silva', 'hasini.silva93@example.com', '075-0318477', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (94, '700000094V', 'Sanduni Silva', 'sanduni.silva94@example.com', '075-4543481', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (95, '700000095V', 'Shenal Gunasekara', 'shenal.gunasekara95@example.com', '078-8640740', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (96, '700000096V', 'Chathura Karunaratne', 'chathura.karunaratne96@example.com', '071-9263260', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (97, '700000097V', 'Ishani Peiris', 'ishani.peiris97@example.com', '076-6743070', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (98, '700000098V', 'Sachini Ranasinghe', 'sachini.ranasinghe98@example.com', '075-1420007', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (99, '700000099V', 'Ruwan Karunaratne', 'ruwan.karunaratne99@example.com', '073-1964512', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (100, '700000100V', 'Sajith Jayasinghe', 'sajith.jayasinghe100@example.com', '076-6755655', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (101, '700000101V', 'Hasini Ekanayake', 'hasini.ekanayake101@example.com', '076-2316679', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (102, '700000102V', 'Hasini Bandara', 'hasini.bandara102@example.com', '075-2091641', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (103, '700000103V', 'Pasindu Gunasekara', 'pasindu.gunasekara103@example.com', '074-9558258', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (104, '700000104V', 'Pramudi Karunaratne', 'pramudi.karunaratne104@example.com', '071-4971142', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (105, '700000105V', 'Lakmini Weerasinghe', 'lakmini.weerasinghe105@example.com', '073-3322936', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (106, '700000106V', 'Kavindu Fernando', 'kavindu.fernando106@example.com', '074-2338592', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (107, '700000107V', 'Nimal Abeysekera', 'nimal.abeysekera107@example.com', '078-6937480', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (108, '700000108V', 'Hasini Silva', 'hasini.silva108@example.com', '074-3934589', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (109, '700000109V', 'Chamath Abeysekera', 'chamath.abeysekera109@example.com', '078-1624488', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (110, '700000110V', 'Dinuka Karunaratne', 'dinuka.karunaratne110@example.com', '077-1009271', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (111, '700000111V', 'Tharindu Fernando', 'tharindu.fernando111@example.com', '073-1467102', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (112, '700000112V', 'Sajith Gunasekara', 'sajith.gunasekara112@example.com', '074-2990420', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (113, '700000113V', 'Malith Fernando', 'malith.fernando113@example.com', '073-1437983', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (114, '700000114V', 'Nuwan Fernando', 'nuwan.fernando114@example.com', '072-6939343', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (115, '700000115V', 'Pramudi Bandara', 'pramudi.bandara115@example.com', '076-9499734', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (116, '700000116V', 'Lakmini Perera', 'lakmini.perera116@example.com', '072-4313097', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (117, '700000117V', 'Kavindu Gunasekara', 'kavindu.gunasekara117@example.com', '075-1486708', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (118, '700000118V', 'Lakmini Peiris', 'lakmini.peiris118@example.com', '073-0339646', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (119, '700000119V', 'Malith Silva', 'malith.silva119@example.com', '073-5769492', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (120, '700000120V', 'Supun Abeysekera', 'supun.abeysekera120@example.com', '072-0485947', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (121, '700000121V', 'Nuwan Ranasinghe', 'nuwan.ranasinghe121@example.com', '073-4090730', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (122, '700000122V', 'Pasindu Silva', 'pasindu.silva122@example.com', '078-1369365', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (123, '700000123V', 'Thisara Fernando', 'thisara.fernando123@example.com', '072-7463054', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (124, '700000124V', 'Ishara Perera', 'ishara.perera124@example.com', '072-8481763', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (125, '700000125V', 'Pasindu Abeysekera', 'pasindu.abeysekera125@example.com', '076-4148286', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (126, '700000126V', 'Dulani Bandara', 'dulani.bandara126@example.com', '073-2275088', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (127, '700000127V', 'Maneesha Ranasinghe', 'maneesha.ranasinghe127@example.com', '075-0745110', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (128, '700000128V', 'Pasindu Abeysekera', 'pasindu.abeysekera128@example.com', '073-2602365', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (129, '700000129V', 'Hasini Abeysekera', 'hasini.abeysekera129@example.com', '078-3531571', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (130, '700000130V', 'Ishara Karunaratne', 'ishara.karunaratne130@example.com', '077-7685944', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (131, '700000131V', 'Kasun Weerasinghe', 'kasun.weerasinghe131@example.com', '073-0153251', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (132, '700000132V', 'Dulani Wickramasinghe', 'dulani.wickramasinghe132@example.com', '078-5092251', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (133, '700000133V', 'Dinuka Weerasinghe', 'dinuka.weerasinghe133@example.com', '072-9559854', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (134, '700000134V', 'Supun Wickramasinghe', 'supun.wickramasinghe134@example.com', '074-3555249', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (135, '700000135V', 'Pasindu Ranasinghe', 'pasindu.ranasinghe135@example.com', '075-1252679', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (136, '700000136V', 'Roshan Fernando', 'roshan.fernando136@example.com', '074-1314324', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (137, '700000137V', 'Lakmini Wickramasinghe', 'lakmini.wickramasinghe137@example.com', '077-9964438', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (138, '700000138V', 'Sanduni Ranasinghe', 'sanduni.ranasinghe138@example.com', '073-1282723', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (139, '700000139V', 'Ishani Wijesinghe', 'ishani.wijesinghe139@example.com', '077-8292672', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (140, '700000140V', 'Tharindu Abeysekera', 'tharindu.abeysekera140@example.com', '075-6847106', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (141, '700000141V', 'Hasini Karunaratne', 'hasini.karunaratne141@example.com', '078-5649804', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (142, '700000142V', 'Ishani Silva', 'ishani.silva142@example.com', '078-3300722', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (143, '700000143V', 'Pasindu Jayasinghe', 'pasindu.jayasinghe143@example.com', '076-9845485', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (144, '700000144V', 'Ishara Jayasinghe', 'ishara.jayasinghe144@example.com', '078-9595790', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (145, '700000145V', 'Kasun Jayasinghe', 'kasun.jayasinghe145@example.com', '073-3096719', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (146, '700000146V', 'Dinuka Karunaratne', 'dinuka.karunaratne146@example.com', '077-0915936', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (147, '700000147V', 'Pasindu Perera', 'pasindu.perera147@example.com', '077-9514435', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (148, '700000148V', 'Tharindu Wijesinghe', 'tharindu.wijesinghe148@example.com', '075-9685992', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (149, '700000149V', 'Sachini Bandara', 'sachini.bandara149@example.com', '074-9561128', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (150, '700000150V', 'Sanduni Ekanayake', 'sanduni.ekanayake150@example.com', '073-5801800', NULL, NULL, NULL, 'Sri Lankan');
INSERT INTO public.guest VALUES (151, NULL, '*** MAINTENANCE ***', 'maintenance@skynest.local', NULL, NULL, NULL, NULL, NULL);


--
-- TOC entry 5393 (class 0 OID 16448)
-- Dependencies: 221
-- Data for Name: invoice; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5395 (class 0 OID 16456)
-- Dependencies: 223
-- Data for Name: payment; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.payment VALUES (1431, 3, 22271.94, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (2, 1, 214500.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (3, 3, 122416.21, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (4, 4, 141817.85, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (5, 5, 202950.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (6, 6, 191789.57, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (7, 6, 64950.43, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (8, 7, 135850.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (9, 8, 234217.03, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (10, 9, 209088.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (11, 10, 343200.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (12, 11, 193600.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (13, 12, 209088.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (14, 13, 58212.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (15, 14, 29754.92, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (16, 14, 17529.96, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (17, 15, 225280.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (18, 16, 261360.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (19, 18, 193600.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (20, 19, 121022.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (21, 20, 151800.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (22, 21, 197410.82, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (23, 21, 117763.45, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (24, 22, 132000.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (25, 23, 231880.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (26, 24, 184800.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (27, 25, 220660.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (28, 26, 88000.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (29, 27, 176000.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (30, 28, 169070.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (31, 29, 48736.76, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (32, 29, 20210.60, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (33, 30, 30024.19, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (34, 30, 7305.45, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (35, 31, 111207.00, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (36, 32, 219340.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (37, 33, 129470.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (38, 34, 226050.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (39, 35, 151910.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (40, 36, 154131.71, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (41, 37, 115893.48, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (42, 38, 36368.53, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (43, 38, 15047.54, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (44, 39, 101038.84, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (45, 39, 59460.39, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (46, 40, 165000.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (47, 41, 149999.08, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (48, 41, 102344.86, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (49, 42, 211200.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (50, 43, 201459.67, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (51, 44, 200939.04, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (52, 46, 235180.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (53, 49, 34464.95, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (54, 49, 26449.25, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (55, 51, 125747.42, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (56, 52, 127600.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (57, 53, 110067.31, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (58, 53, 29632.69, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (59, 54, 173580.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (60, 55, 125745.72, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (61, 55, 61160.80, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (62, 57, 158136.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (63, 58, 116600.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (64, 59, 145200.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (65, 60, 97402.40, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (66, 62, 193600.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (67, 64, 222948.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (68, 65, 215380.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (69, 66, 246400.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (70, 67, 262900.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (71, 69, 178978.98, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (72, 69, 83371.02, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (73, 70, 79200.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (74, 71, 144856.07, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (75, 72, 75240.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (76, 73, 162624.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (77, 74, 129690.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (78, 75, 110440.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (79, 76, 64944.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (80, 77, 90200.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (81, 79, 76476.98, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (82, 81, 162729.60, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (83, 83, 39974.86, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (84, 83, 20882.48, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (85, 84, 87120.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (86, 85, 90420.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (87, 86, 166650.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (88, 87, 104942.33, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (89, 88, 162800.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (90, 90, 65556.57, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (91, 91, 74263.20, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (92, 93, 106590.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (93, 94, 58740.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (94, 95, 39723.32, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (95, 96, 106260.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (96, 97, 153120.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (97, 98, 77462.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (98, 99, 69327.32, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (99, 99, 28716.46, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (100, 100, 105600.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (101, 101, 160248.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (102, 102, 91926.35, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (103, 103, 184800.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (104, 104, 162140.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (105, 105, 68116.40, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (106, 106, 122100.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (107, 108, 250800.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (108, 109, 136620.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (109, 110, 98340.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (110, 111, 96587.11, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (111, 111, 20101.16, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (112, 112, 115940.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (113, 115, 132660.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (114, 116, 125452.80, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (115, 117, 135300.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (116, 118, 28512.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (117, 119, 131450.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (118, 120, 57269.10, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (119, 120, 16118.31, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (120, 121, 52800.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (121, 122, 198110.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (122, 123, 163548.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (123, 124, 32996.51, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (124, 125, 14064.00, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (125, 126, 74474.92, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (126, 126, 34985.98, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (127, 127, 88440.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (128, 128, 49920.91, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (129, 129, 82865.70, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (130, 130, 64584.02, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (131, 130, 48636.17, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (132, 131, 94089.60, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (133, 134, 94089.60, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (134, 136, 112640.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (135, 137, 110440.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (136, 138, 80863.20, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (137, 139, 27324.95, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (138, 139, 29154.16, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (139, 140, 165066.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (140, 141, 135326.40, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (141, 142, 29040.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (142, 144, 38095.28, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (143, 144, 29939.02, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (144, 145, 111936.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (145, 146, 124960.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (146, 147, 90200.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (147, 149, 135850.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (148, 150, 114400.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (149, 151, 73649.80, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (150, 151, 28643.21, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (151, 152, 68673.02, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (152, 153, 76996.86, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (153, 154, 119240.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (154, 155, 119460.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (155, 156, 66949.18, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (156, 157, 192720.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (157, 158, 123459.60, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (158, 159, 122870.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (159, 160, 110225.39, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (160, 160, 40050.34, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (161, 161, 116567.54, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (162, 161, 29465.75, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (163, 162, 135602.13, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (164, 162, 34347.87, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (165, 163, 190080.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (166, 165, 120971.79, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (167, 166, 144540.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (168, 167, 79200.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (169, 168, 49601.82, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (170, 168, 15897.60, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (171, 169, 92312.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (172, 170, 164780.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (173, 171, 98564.84, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (174, 174, 53198.15, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (175, 175, 105600.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (176, 176, 73937.56, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (177, 176, 14633.83, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (178, 177, 164516.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (179, 179, 89931.18, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (180, 179, 57483.45, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (181, 180, 72444.72, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (182, 181, 15781.57, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (183, 182, 140826.40, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (184, 183, 42431.91, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (185, 183, 32098.83, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (186, 185, 74041.37, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (187, 185, 45837.96, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (188, 186, 58080.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (189, 187, 98230.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (190, 188, 160160.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (191, 190, 70089.99, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (192, 191, 48189.04, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (193, 193, 77220.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (194, 196, 10637.73, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (195, 197, 66000.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (196, 198, 150739.60, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (197, 199, 87250.81, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (198, 200, 52762.40, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (199, 201, 33293.83, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (200, 202, 151250.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (201, 203, 113520.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (202, 204, 81510.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (203, 206, 25080.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (204, 207, 77253.85, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (205, 207, 28282.46, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (206, 208, 108685.55, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (207, 208, 16848.81, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (208, 209, 94089.60, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (209, 210, 154000.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (210, 211, 82710.66, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (211, 212, 79200.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (212, 213, 106920.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (213, 214, 11155.79, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (214, 214, 6223.89, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (215, 215, 69652.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (216, 216, 55440.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (217, 217, 112856.27, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (218, 217, 33179.73, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (219, 218, 125400.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (220, 219, 58594.80, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (221, 220, 20361.77, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (222, 221, 89734.31, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (223, 222, 157740.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (224, 223, 44662.99, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (225, 223, 14098.63, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (226, 226, 130039.48, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (227, 226, 24630.22, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (228, 227, 141240.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (229, 228, 143000.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (230, 230, 56760.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (231, 231, 55391.42, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (232, 231, 58480.48, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (233, 232, 14511.24, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (234, 232, 6546.92, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (235, 233, 118967.20, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (236, 234, 44110.09, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (237, 235, 56535.64, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (238, 237, 74295.51, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (239, 237, 14913.66, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (240, 238, 99000.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (241, 240, 39600.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (242, 241, 99000.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (243, 242, 85536.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (244, 243, 59400.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (245, 244, 150347.08, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (246, 245, 45786.37, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (247, 247, 105403.45, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (248, 247, 51367.35, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (249, 248, 24323.01, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (250, 248, 14851.37, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (251, 249, 52140.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (252, 250, 82262.40, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (253, 251, 132330.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (254, 252, 78437.21, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (255, 253, 37623.23, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (256, 254, 102339.60, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (257, 255, 103567.20, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (258, 257, 67320.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (259, 258, 151417.20, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (260, 259, 54009.10, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (261, 259, 14419.78, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (262, 260, 111870.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (263, 261, 32282.28, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (264, 261, 11324.43, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (265, 262, 63102.99, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (266, 262, 43771.45, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (267, 264, 157740.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (268, 265, 35776.31, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (269, 266, 84810.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (270, 267, 62631.87, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (271, 267, 15727.23, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (272, 268, 189420.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (273, 269, 56095.84, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (274, 270, 70567.20, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (275, 271, 84810.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (276, 272, 78114.91, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (277, 272, 24554.69, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (278, 273, 64020.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (279, 274, 44565.87, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (280, 274, 37624.21, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (281, 275, 110440.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (282, 276, 51368.00, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (283, 276, 16105.14, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (284, 277, 57564.77, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (285, 277, 13031.29, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (286, 278, 50894.80, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (287, 279, 59082.34, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (288, 280, 127529.60, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (289, 281, 155320.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (290, 282, 43560.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (291, 283, 56061.05, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (292, 284, 107470.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (293, 285, 110643.45, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (294, 285, 45996.55, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (295, 286, 45127.23, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (296, 287, 43459.75, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (297, 288, 50226.16, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (298, 289, 33000.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (299, 290, 46254.49, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (300, 290, 16579.56, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (301, 291, 33975.87, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (302, 292, 133870.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (303, 293, 104447.20, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (304, 294, 87120.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (305, 296, 84097.20, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (306, 297, 53111.17, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (307, 297, 35770.89, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (308, 298, 22099.29, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (309, 298, 20801.51, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (310, 299, 49830.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (311, 301, 43560.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (312, 302, 32309.66, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (313, 303, 116270.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (314, 304, 83142.65, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (315, 306, 24182.40, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (316, 307, 80740.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (317, 308, 125400.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (318, 309, 52816.30, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (319, 309, 19520.46, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (320, 310, 105336.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (321, 311, 44363.14, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (322, 311, 26202.50, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (323, 312, 97630.22, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (324, 312, 35684.91, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (325, 313, 148500.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (326, 314, 125400.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (327, 315, 75195.73, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (328, 316, 80109.94, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (329, 316, 15897.91, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (330, 317, 130020.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (331, 318, 74899.89, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (332, 318, 26410.11, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (333, 319, 50933.81, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (334, 320, 127380.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (335, 321, 106920.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (336, 322, 182089.60, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (337, 323, 110827.20, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (338, 324, 27891.74, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (339, 326, 136620.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (340, 327, 49877.46, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (341, 328, 74250.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (342, 329, 96536.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (343, 330, 76820.33, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (344, 332, 97042.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (345, 333, 39863.03, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (346, 334, 80388.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (347, 335, 23635.08, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (348, 336, 107619.60, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (349, 337, 135300.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (350, 338, 108757.08, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (351, 339, 59730.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (352, 340, 70348.52, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (353, 340, 19411.48, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (354, 342, 69062.40, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (355, 343, 84810.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (356, 344, 96910.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (357, 346, 62269.05, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (358, 346, 29418.15, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (359, 347, 68790.07, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (360, 348, 51810.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (361, 349, 73260.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (362, 350, 27862.02, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (363, 351, 95810.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (364, 352, 89284.80, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (365, 353, 78540.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (366, 354, 80300.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (367, 355, 40048.11, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (368, 355, 34655.42, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (369, 356, 71720.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (370, 357, 41052.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (371, 358, 66000.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (372, 359, 22639.56, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (373, 360, 55398.54, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (374, 362, 39600.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (375, 363, 17383.87, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (376, 364, 22059.80, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (377, 365, 83930.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (378, 366, 31598.23, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (379, 367, 19127.63, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (380, 368, 70476.14, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (381, 369, 95150.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (382, 370, 46240.12, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (383, 370, 11839.88, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (384, 371, 100663.20, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (385, 372, 12567.98, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (386, 373, 41690.70, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (387, 374, 7429.19, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (388, 375, 51810.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (389, 376, 41026.75, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (390, 376, 13533.25, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (391, 377, 44880.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (392, 378, 29153.89, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (393, 379, 32340.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (394, 380, 14256.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (395, 382, 18643.63, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (396, 383, 27402.14, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (397, 385, 64900.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (398, 386, 92400.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (399, 387, 66000.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (400, 389, 83693.01, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (401, 390, 50840.84, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (402, 391, 73345.12, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (403, 391, 23665.05, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (404, 392, 84480.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (405, 393, 102876.40, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (406, 394, 130130.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (407, 395, 123310.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (408, 396, 15681.60, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (409, 397, 62040.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (410, 398, 27786.53, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (411, 398, 13612.58, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (412, 399, 112750.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (413, 401, 35721.72, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (414, 401, 24068.81, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (415, 402, 98582.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (416, 403, 14808.86, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (417, 403, 2803.48, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (418, 404, 31900.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (419, 406, 125400.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (420, 407, 57024.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (421, 408, 110880.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (422, 409, 38246.81, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (423, 409, 11759.13, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (424, 410, 98340.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (425, 411, 65890.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (426, 412, 88240.38, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (427, 412, 29266.02, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (428, 413, 11550.56, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (429, 413, 3629.44, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (430, 414, 91608.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (431, 416, 38060.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (432, 417, 92840.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (433, 418, 54120.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (434, 419, 53648.62, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (435, 419, 8215.61, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (436, 420, 27231.60, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (437, 421, 102388.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (438, 422, 48523.20, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (439, 425, 25080.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (440, 427, 15387.04, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (441, 427, 11172.16, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (442, 429, 109164.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (443, 430, 72600.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (444, 431, 34100.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (445, 432, 41103.08, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (446, 432, 22945.64, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (447, 433, 82526.40, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (448, 435, 76428.89, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (449, 436, 12376.02, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (450, 437, 10178.59, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (451, 438, 90860.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (452, 440, 38820.83, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (453, 440, 24027.58, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (454, 441, 35835.25, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (455, 442, 78408.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (456, 443, 31363.20, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (457, 444, 58080.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (458, 445, 96897.21, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (459, 447, 14620.24, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (460, 448, 99000.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (461, 449, 29040.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (462, 451, 56518.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (463, 452, 44817.85, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (464, 452, 12471.79, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (465, 453, 44352.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (466, 454, 56357.81, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (467, 454, 32906.32, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (468, 455, 88330.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (469, 456, 69960.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (470, 457, 47617.00, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (471, 457, 14796.86, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (472, 458, 25448.79, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (473, 459, 90226.40, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (474, 460, 40590.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (475, 461, 29040.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (476, 462, 15667.99, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (477, 463, 84727.73, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (478, 463, 33522.27, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (479, 465, 62541.10, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (480, 466, 76586.40, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (481, 467, 60403.20, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (482, 468, 18480.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (483, 469, 127710.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (484, 470, 64680.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (485, 472, 44550.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (486, 473, 133980.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (487, 474, 260150.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (488, 476, 88000.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (489, 477, 33857.25, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (490, 477, 19029.38, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (491, 478, 148203.10, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (492, 478, 49961.16, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (493, 479, 97172.07, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (494, 480, 89320.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (495, 481, 156816.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (496, 482, 78170.78, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (497, 483, 226600.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (498, 485, 342760.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (499, 486, 129239.69, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (500, 486, 39786.31, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (501, 487, 172865.22, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (502, 487, 32684.25, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (503, 489, 137800.22, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (504, 489, 37055.78, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (505, 490, 163680.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (506, 491, 55712.22, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (507, 491, 17368.05, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (508, 492, 158840.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (509, 493, 127827.93, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (510, 494, 151800.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (511, 495, 186576.67, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (512, 496, 229460.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (513, 497, 143000.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (514, 499, 67311.83, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (515, 499, 30478.46, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (516, 501, 129580.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (517, 503, 206800.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (518, 504, 101454.18, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (519, 505, 123574.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (520, 507, 210540.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (521, 508, 140844.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (522, 509, 122531.92, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (523, 510, 48400.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (524, 512, 125994.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (525, 513, 75231.93, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (526, 514, 45900.87, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (527, 514, 40282.28, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (528, 515, 116600.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (529, 517, 220000.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (530, 518, 88000.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (531, 519, 30996.48, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (532, 520, 204930.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (533, 522, 94820.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (534, 523, 148399.65, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (535, 523, 55254.14, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (536, 524, 147950.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (537, 525, 49706.01, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (538, 525, 17599.93, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (539, 527, 215688.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (540, 528, 170016.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (541, 529, 136400.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (542, 530, 160666.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (543, 531, 57921.78, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (544, 531, 36054.08, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (545, 532, 194507.29, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (546, 533, 193600.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (547, 534, 109269.97, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (548, 534, 43336.64, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (549, 535, 146828.27, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (550, 536, 129800.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (551, 537, 284900.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (552, 538, 59477.60, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (553, 538, 12514.30, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (554, 539, 83205.71, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (555, 539, 49603.15, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (556, 540, 110000.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (557, 541, 170544.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (558, 542, 276760.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (559, 543, 83160.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (560, 544, 41636.92, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (561, 544, 7928.08, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (562, 545, 11291.56, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (563, 545, 13173.25, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (564, 546, 65328.81, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (565, 546, 46810.98, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (566, 547, 80630.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (567, 548, 37400.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (568, 549, 82852.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (569, 551, 56760.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (570, 552, 48674.20, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (571, 553, 131282.80, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (572, 554, 58300.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (573, 555, 98670.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (574, 557, 120010.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (575, 558, 85140.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (576, 559, 58080.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (577, 560, 79168.19, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (578, 561, 98670.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (579, 562, 172752.80, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (580, 565, 164076.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (581, 566, 73363.68, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (582, 566, 9317.89, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (583, 567, 37060.09, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (584, 568, 102936.93, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (585, 568, 44793.61, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (586, 569, 165330.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (587, 570, 61171.98, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (588, 570, 13390.20, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (589, 571, 65010.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (590, 572, 92444.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (591, 573, 113300.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (592, 575, 87095.40, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (593, 575, 26424.60, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (594, 576, 155760.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (595, 577, 115526.40, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (596, 578, 33002.67, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (597, 579, 102537.38, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (598, 579, 47662.47, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (599, 583, 105380.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (600, 584, 110564.62, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (601, 584, 44588.18, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (602, 585, 145200.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (603, 587, 96470.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (604, 588, 124106.40, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (605, 589, 188760.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (606, 590, 24590.55, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (607, 592, 49014.67, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (608, 592, 17357.85, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (609, 593, 51009.12, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (610, 593, 48856.08, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (611, 595, 227040.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (612, 596, 105600.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (613, 597, 93390.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (614, 600, 139642.80, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (615, 601, 187110.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (616, 602, 189860.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (617, 604, 33281.80, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (618, 605, 18600.83, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (619, 605, 9044.69, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (620, 606, 85093.66, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (621, 607, 137720.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (622, 608, 78126.40, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (623, 609, 29843.34, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (624, 609, 15337.76, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (625, 610, 88123.20, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (626, 611, 111122.49, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (627, 611, 51242.05, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (628, 612, 143589.60, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (629, 614, 137940.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (630, 615, 105049.31, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (631, 615, 35200.69, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (632, 616, 172920.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (633, 617, 149776.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (634, 618, 54120.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (635, 619, 24579.76, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (636, 619, 12097.88, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (637, 621, 183700.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (638, 622, 108796.68, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (639, 622, 24016.74, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (640, 623, 253616.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (641, 624, 52807.28, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (642, 624, 19192.87, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (643, 625, 61930.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (644, 626, 33000.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (645, 627, 41949.00, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (646, 628, 24324.34, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (647, 628, 22837.41, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (648, 629, 163416.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (649, 630, 160710.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (650, 631, 23768.52, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (651, 631, 17051.20, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (652, 632, 201960.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (653, 633, 108570.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (654, 636, 123186.77, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (655, 638, 113262.11, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (656, 639, 64102.56, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (657, 640, 81463.06, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (658, 640, 18605.67, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (659, 641, 61786.10, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (660, 641, 40277.77, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (661, 642, 146664.33, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (662, 643, 51882.09, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (663, 644, 23523.43, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (664, 644, 6445.24, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (665, 645, 34415.78, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (666, 646, 48290.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (667, 648, 43454.66, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (668, 649, 66445.29, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (669, 651, 28840.89, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (670, 651, 12983.79, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (671, 653, 98670.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (672, 654, 82433.48, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (673, 656, 146009.60, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (674, 657, 72145.13, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (675, 658, 76549.11, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (676, 658, 38661.04, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (677, 659, 56876.77, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (678, 659, 18115.73, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (679, 660, 119570.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (680, 661, 174240.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (681, 662, 113080.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (682, 663, 36582.35, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (683, 663, 10496.59, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (684, 664, 77991.68, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (685, 664, 20848.62, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (686, 665, 89892.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (687, 666, 31190.62, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (688, 667, 93060.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (689, 668, 41580.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (690, 669, 21780.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (691, 670, 20698.16, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (692, 670, 13189.41, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (693, 671, 30666.39, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (694, 672, 34862.67, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (695, 672, 8752.13, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (696, 673, 52565.96, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (697, 674, 195360.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (698, 675, 101970.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (699, 676, 78540.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (700, 677, 173800.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (701, 678, 118140.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (702, 680, 109489.60, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (703, 681, 143000.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (704, 682, 55940.54, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (705, 682, 26290.22, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (706, 683, 65340.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (707, 684, 48364.80, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (708, 685, 109890.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (709, 686, 41231.67, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (710, 686, 22698.50, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (711, 687, 58960.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (712, 688, 96987.67, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (713, 689, 142560.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (714, 690, 95700.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (715, 691, 83160.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (716, 692, 52595.01, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (717, 692, 22581.23, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (718, 693, 64020.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (719, 694, 99000.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (720, 695, 174900.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (721, 697, 110167.20, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (722, 698, 58764.17, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (723, 699, 64390.72, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (724, 699, 29564.18, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (725, 700, 63297.53, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (726, 702, 33603.99, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (727, 703, 40770.41, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (728, 703, 28992.60, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (729, 704, 100029.60, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (730, 705, 29883.80, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (731, 705, 14493.32, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (732, 706, 174900.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (733, 708, 47300.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (734, 709, 36314.67, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (735, 709, 14025.47, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (736, 710, 132000.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (737, 712, 79200.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (738, 713, 73164.46, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (739, 715, 84150.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (740, 717, 73040.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (741, 718, 136567.20, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (742, 719, 57360.02, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (743, 720, 87120.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (744, 721, 101420.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (745, 722, 55748.63, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (746, 723, 126720.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (747, 724, 73590.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (748, 725, 160512.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (749, 726, 54072.60, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (750, 726, 10309.51, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (751, 727, 53276.33, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (752, 728, 110550.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (753, 729, 99000.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (754, 730, 47273.41, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (755, 732, 30074.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (756, 733, 51546.52, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (757, 734, 70092.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (758, 735, 32214.87, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (759, 736, 59523.21, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (760, 736, 31551.47, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (761, 737, 83930.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (762, 738, 28802.40, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (763, 739, 107140.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (764, 741, 40034.37, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (765, 742, 49742.71, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (766, 742, 30195.72, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (767, 743, 30157.49, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (768, 743, 17360.04, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (769, 744, 102630.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (770, 745, 141240.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (771, 746, 99330.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (772, 748, 45431.54, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (773, 748, 27820.37, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (774, 749, 74580.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (775, 750, 101565.14, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (776, 752, 80850.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (777, 753, 100980.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (778, 754, 106920.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (779, 755, 72633.86, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (780, 756, 132000.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (781, 757, 131010.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (782, 758, 30103.62, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (783, 759, 167112.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (784, 760, 73040.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (785, 761, 119460.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (786, 762, 144540.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (787, 764, 99660.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (788, 765, 50311.23, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (789, 765, 16099.38, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (790, 766, 44880.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (791, 767, 49060.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (792, 769, 99442.10, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (793, 769, 29008.45, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (794, 770, 116820.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (795, 771, 59694.80, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (796, 772, 21780.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (797, 773, 59400.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (798, 774, 16054.06, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (799, 774, 3291.24, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (800, 775, 59400.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (801, 776, 38287.63, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (802, 776, 21186.69, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (803, 777, 19235.46, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (804, 777, 7482.94, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (805, 778, 15236.22, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (806, 779, 22550.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (807, 780, 139700.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (808, 781, 137676.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (809, 782, 32525.30, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (810, 783, 119460.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (811, 784, 51664.80, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (812, 787, 23522.40, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (813, 788, 141680.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (814, 789, 63874.80, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (815, 790, 70891.94, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (816, 791, 146410.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (817, 792, 141900.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (818, 793, 114840.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (819, 795, 33330.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (820, 796, 20537.06, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (821, 797, 55843.62, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (822, 797, 35467.19, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (823, 798, 157740.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (824, 799, 49684.80, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (825, 800, 65741.97, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (826, 801, 84150.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (827, 803, 53336.91, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (828, 806, 118470.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (829, 807, 37642.97, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (830, 807, 22645.30, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (831, 808, 125400.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (832, 809, 105600.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (833, 810, 80520.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (834, 811, 79310.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (835, 812, 129967.20, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (836, 813, 146520.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (837, 814, 49930.46, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (838, 814, 29269.54, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (839, 816, 83930.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (840, 817, 102300.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (841, 818, 95444.12, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (842, 818, 32705.88, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (843, 819, 74527.20, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (844, 820, 89760.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (845, 821, 139370.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (846, 822, 141900.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (847, 823, 53680.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (848, 824, 33478.08, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (849, 825, 46742.12, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (850, 826, 77444.19, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (851, 827, 63121.28, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (852, 827, 36010.83, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (853, 828, 80669.36, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (854, 830, 46796.46, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (855, 830, 7184.74, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (856, 831, 60720.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (857, 832, 38622.04, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (858, 833, 41580.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (859, 834, 11747.89, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (860, 837, 50510.28, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (861, 838, 71067.71, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (862, 838, 25543.51, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (863, 839, 83490.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (864, 840, 37230.84, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (865, 841, 53718.92, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (866, 842, 70426.40, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (867, 843, 81895.42, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (868, 845, 82478.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (869, 846, 140800.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (870, 847, 15728.42, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (871, 848, 91423.20, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (872, 849, 77220.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (873, 850, 80044.80, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (874, 851, 71280.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (875, 852, 47030.34, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (876, 853, 108768.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (877, 854, 72600.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (878, 855, 58168.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (879, 856, 79200.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (880, 857, 58630.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (881, 860, 14906.41, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (882, 861, 160358.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (883, 862, 59510.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (884, 863, 90446.40, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (885, 864, 55140.53, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (886, 864, 21539.64, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (887, 865, 32160.75, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (888, 866, 71222.15, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (889, 867, 14520.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (890, 868, 13522.59, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (891, 868, 9843.22, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (892, 869, 163376.40, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (893, 870, 97460.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (894, 871, 24880.53, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (895, 873, 49118.15, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (896, 874, 73590.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (897, 876, 48958.00, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (898, 876, 19873.23, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (899, 877, 106128.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (900, 878, 141240.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (901, 879, 86900.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (902, 880, 75652.27, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (903, 881, 141900.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (904, 882, 75900.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (905, 884, 18456.65, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (906, 884, 6541.50, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (907, 885, 50499.08, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (908, 886, 60940.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (909, 889, 47397.63, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (910, 891, 57812.95, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (911, 892, 88110.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (912, 895, 65753.18, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (913, 896, 16399.15, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (914, 897, 59175.80, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (915, 898, 26711.79, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (916, 898, 25822.66, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (917, 899, 101750.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (918, 900, 59730.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (919, 902, 78540.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (920, 903, 98824.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (921, 905, 11157.68, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (922, 905, 2954.73, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (923, 906, 37978.58, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (924, 907, 62896.07, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (925, 907, 39238.11, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (926, 908, 18981.60, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (927, 912, 30643.30, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (928, 913, 69630.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (929, 914, 44863.97, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (930, 915, 67210.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (931, 917, 51583.97, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (932, 918, 82526.40, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (933, 919, 99660.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (934, 920, 141240.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (935, 921, 94894.80, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (936, 922, 53305.93, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (937, 923, 42768.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (938, 924, 87780.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (939, 925, 19551.96, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (940, 925, 4248.39, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (941, 926, 126865.78, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (942, 928, 100980.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (943, 929, 45952.75, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (944, 929, 16602.42, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (945, 930, 65197.03, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (946, 931, 78408.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (947, 932, 11403.19, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (948, 933, 135080.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (949, 934, 80300.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (950, 935, 17494.02, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (951, 935, 14470.30, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (952, 936, 40899.26, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (953, 937, 59070.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (954, 938, 103290.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (955, 939, 14527.56, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (956, 939, 4616.86, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (957, 940, 45870.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (958, 942, 43597.44, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (959, 942, 35785.76, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (960, 943, 77880.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (961, 944, 29170.13, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (962, 944, 16512.42, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (963, 945, 105454.48, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (964, 945, 40744.47, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (965, 946, 204600.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (966, 947, 276540.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (967, 948, 39705.61, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (968, 948, 17410.53, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (969, 949, 135300.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (970, 950, 98751.24, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (971, 951, 51040.39, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (972, 951, 43335.93, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (973, 953, 121000.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (974, 955, 122185.97, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (975, 956, 309100.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (976, 957, 152240.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (977, 958, 208340.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (978, 959, 77944.08, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (979, 960, 59835.46, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (980, 962, 102850.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (981, 963, 213048.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (982, 964, 70069.31, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (983, 965, 143569.01, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (984, 966, 153450.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (985, 967, 173140.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (986, 968, 34148.32, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (987, 969, 206030.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (988, 970, 231440.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (989, 971, 178200.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (990, 972, 104500.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (991, 974, 217800.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (992, 975, 176330.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (993, 976, 304260.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (994, 977, 236808.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (995, 978, 58308.59, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (996, 979, 229416.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (997, 980, 191400.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (998, 981, 277640.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (999, 982, 117260.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1000, 984, 91947.89, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1001, 984, 37788.56, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1002, 985, 101554.60, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1003, 986, 136394.80, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1004, 987, 52272.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1005, 988, 106673.78, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1006, 989, 178640.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1007, 990, 88000.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1008, 991, 93824.01, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1009, 991, 37973.62, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1010, 992, 162360.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1011, 993, 162360.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1012, 994, 288200.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1013, 995, 150700.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1014, 996, 110365.34, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1015, 996, 56232.16, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1016, 997, 209088.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1017, 998, 117040.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1018, 999, 243980.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1019, 1000, 105050.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1020, 1002, 232518.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1021, 1003, 171453.14, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1022, 1003, 50547.27, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1023, 1004, 121003.12, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1024, 1007, 284328.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1025, 1008, 75286.04, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1026, 1009, 212916.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1027, 1010, 103233.66, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1028, 1011, 145200.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1029, 1012, 9121.17, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1030, 1014, 103289.34, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1031, 1014, 42244.80, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1032, 1015, 150810.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1033, 1016, 145200.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1034, 1017, 74800.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1035, 1018, 59683.43, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1036, 1019, 58080.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1037, 1020, 127160.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1038, 1022, 115526.40, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1039, 1024, 242616.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1040, 1025, 133689.60, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1041, 1026, 215160.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1042, 1027, 155042.80, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1043, 1029, 112226.40, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1044, 1030, 84132.49, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1045, 1031, 30149.94, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1046, 1033, 142502.80, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1047, 1037, 93965.41, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1048, 1037, 53904.81, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1049, 1039, 28512.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1050, 1040, 25989.19, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1051, 1040, 11633.36, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1052, 1041, 56184.53, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1053, 1041, 18202.79, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1054, 1043, 81212.24, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1055, 1043, 33737.76, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1056, 1044, 31647.27, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1057, 1045, 231000.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1058, 1046, 75681.78, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1059, 1046, 43448.22, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1060, 1047, 152900.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1061, 1048, 169510.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1062, 1049, 62726.40, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1063, 1050, 97020.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1064, 1051, 16682.71, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1065, 1052, 125840.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1066, 1053, 129302.80, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1067, 1054, 161700.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1068, 1055, 31887.03, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1069, 1056, 95415.66, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1070, 1058, 125563.65, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1071, 1060, 76474.68, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1072, 1061, 97262.24, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1073, 1062, 63481.67, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1074, 1062, 20788.38, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1075, 1063, 117150.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1076, 1064, 108890.64, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1077, 1065, 36809.53, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1078, 1065, 16162.04, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1079, 1066, 33485.76, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1080, 1067, 38860.95, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1081, 1067, 8327.00, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1082, 1069, 106150.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1083, 1070, 157080.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1084, 1071, 68213.20, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1085, 1072, 101336.40, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1086, 1073, 194260.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1087, 1074, 129360.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1088, 1075, 89126.40, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1089, 1076, 54561.33, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1090, 1077, 115521.69, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1091, 1077, 31351.58, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1092, 1078, 66622.25, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1093, 1079, 63255.84, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1094, 1079, 15991.10, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1095, 1080, 135248.24, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1096, 1081, 55501.94, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1097, 1082, 145200.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1098, 1083, 65838.03, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1099, 1084, 18953.27, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1100, 1084, 21118.76, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1101, 1085, 103224.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1102, 1089, 102960.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1103, 1091, 118800.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1104, 1092, 125413.20, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1105, 1093, 77880.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1106, 1094, 87120.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1107, 1095, 33463.32, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1108, 1095, 11717.25, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1109, 1096, 47740.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1110, 1097, 55681.63, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1111, 1097, 20481.82, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1112, 1098, 107580.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1113, 1099, 109230.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1114, 1101, 153450.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1115, 1102, 92072.22, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1116, 1102, 68944.24, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1117, 1104, 39500.20, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1118, 1105, 88611.14, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1119, 1106, 94089.60, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1120, 1107, 129360.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1121, 1108, 35896.46, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1122, 1109, 34650.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1123, 1110, 56485.23, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1124, 1110, 35434.01, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1125, 1111, 178860.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1126, 1112, 110396.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1127, 1113, 53101.05, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1128, 1113, 46038.59, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1129, 1115, 31900.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1130, 1118, 189970.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1131, 1120, 15200.99, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1132, 1121, 159940.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1133, 1122, 125452.80, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1134, 1123, 74789.62, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1135, 1123, 25316.38, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1136, 1124, 79200.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1137, 1126, 79724.73, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1138, 1128, 95040.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1139, 1129, 34980.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1140, 1130, 94089.60, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1141, 1131, 53994.95, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1142, 1131, 34297.16, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1143, 1132, 26222.82, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1144, 1132, 17593.22, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1145, 1133, 76638.08, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1146, 1133, 31233.90, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1147, 1134, 136620.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1148, 1135, 116160.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1149, 1137, 81392.50, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1150, 1138, 75278.15, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1151, 1138, 43409.38, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1152, 1142, 31753.85, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1153, 1142, 11316.11, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1154, 1143, 49363.67, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1155, 1145, 152240.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1156, 1146, 59316.76, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1157, 1147, 45430.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1158, 1149, 47826.93, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1159, 1150, 88624.80, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1160, 1151, 49864.93, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1161, 1152, 124212.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1162, 1153, 88109.60, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1163, 1154, 88184.80, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1164, 1155, 140800.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1165, 1156, 134640.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1166, 1157, 132000.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1167, 1158, 69482.48, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1168, 1158, 43382.00, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1169, 1159, 41379.50, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1170, 1159, 24430.25, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1171, 1160, 125400.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1172, 1161, 99550.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1173, 1162, 59400.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1174, 1164, 33192.96, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1175, 1164, 25182.26, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1176, 1165, 36095.80, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1177, 1165, 6747.15, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1178, 1166, 152829.60, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1179, 1167, 83140.47, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1180, 1167, 26419.53, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1181, 1169, 154566.91, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1182, 1169, 40172.69, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1183, 1171, 140250.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1184, 1172, 85140.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1185, 1173, 49292.98, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1186, 1173, 10516.07, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1187, 1174, 157779.60, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1188, 1175, 72354.47, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1189, 1176, 42599.28, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1190, 1176, 13839.57, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1191, 1177, 48712.40, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1192, 1178, 128260.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1193, 1179, 65340.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1194, 1180, 143440.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1195, 1181, 81400.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1196, 1182, 75108.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1197, 1184, 34775.14, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1198, 1184, 10764.86, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1199, 1185, 112640.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1200, 1186, 33723.83, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1201, 1187, 36425.01, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1202, 1188, 124740.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1203, 1191, 88440.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1204, 1193, 17911.31, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1205, 1194, 28193.56, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1206, 1195, 100113.95, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1207, 1195, 45015.65, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1208, 1196, 40742.22, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1209, 1197, 87120.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1210, 1198, 73590.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1211, 1199, 89100.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1212, 1200, 94380.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1213, 1201, 35170.95, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1214, 1201, 5151.48, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1215, 1202, 44552.41, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1216, 1203, 65842.93, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1217, 1203, 37688.39, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1218, 1204, 112860.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1219, 1205, 47520.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1220, 1206, 217536.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1221, 1207, 68107.57, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1222, 1208, 172260.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1223, 1211, 138600.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1224, 1212, 18695.20, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1225, 1213, 157212.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1226, 1214, 60922.80, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1227, 1214, 18277.20, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1228, 1215, 49892.60, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1229, 1216, 109890.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1230, 1217, 103180.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1231, 1219, 33037.33, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1232, 1220, 18206.33, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1233, 1220, 14916.16, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1234, 1221, 60664.70, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1235, 1221, 13349.93, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1236, 1222, 83939.70, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1237, 1222, 31305.10, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1238, 1223, 146520.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1239, 1224, 87120.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1240, 1225, 155139.60, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1241, 1226, 84480.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1242, 1227, 152829.60, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1243, 1228, 73069.78, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1244, 1229, 162360.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1245, 1230, 79200.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1246, 1231, 64152.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1247, 1232, 79565.36, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1248, 1233, 123860.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1249, 1234, 84483.74, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1250, 1234, 24966.26, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1251, 1235, 33575.19, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1252, 1235, 9192.81, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1253, 1237, 89522.40, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1254, 1240, 52847.76, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1255, 1240, 17044.43, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1256, 1241, 19550.17, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1257, 1241, 7603.08, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1258, 1242, 113520.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1259, 1243, 57100.62, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1260, 1243, 15544.63, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1261, 1244, 51004.80, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1262, 1245, 50160.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1263, 1246, 131472.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1264, 1248, 97612.19, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1265, 1249, 63934.84, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1266, 1250, 79200.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1267, 1251, 117546.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1268, 1252, 36440.89, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1269, 1254, 124410.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1270, 1256, 108900.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1271, 1257, 85536.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1272, 1258, 104830.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1273, 1259, 73865.38, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1274, 1259, 55288.72, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1275, 1260, 179520.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1276, 1261, 32091.01, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1277, 1262, 43560.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1278, 1263, 45302.40, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1279, 1265, 83402.89, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1280, 1267, 133100.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1281, 1268, 52889.07, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1282, 1268, 29855.29, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1283, 1269, 66844.80, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1284, 1270, 22867.48, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1285, 1270, 21630.57, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1286, 1271, 51912.82, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1287, 1271, 14967.18, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1288, 1272, 115429.60, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1289, 1273, 87120.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1290, 1274, 45657.74, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1291, 1274, 20484.57, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1292, 1275, 79860.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1293, 1276, 43919.24, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1294, 1276, 22511.27, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1295, 1277, 90200.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1296, 1278, 28986.05, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1297, 1278, 16430.34, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1298, 1279, 139920.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1299, 1281, 49984.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1300, 1282, 101824.42, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1301, 1282, 26873.66, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1302, 1283, 70567.20, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1303, 1284, 139920.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1304, 1285, 105639.60, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1305, 1286, 148500.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1306, 1287, 82666.90, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1307, 1287, 15778.97, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1308, 1288, 119592.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1309, 1289, 145310.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1310, 1291, 31703.41, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1311, 1292, 52984.80, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1312, 1293, 117480.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1313, 1295, 72160.45, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1314, 1296, 43560.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1315, 1297, 74670.96, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1316, 1297, 33899.04, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1317, 1298, 156860.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1318, 1299, 25022.82, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1319, 1299, 7891.82, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1320, 1300, 82698.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1321, 1302, 85800.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1322, 1303, 58172.16, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1323, 1303, 36304.87, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1324, 1304, 63756.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1325, 1305, 54397.19, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1326, 1306, 52800.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1327, 1307, 100980.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1328, 1308, 37405.05, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1329, 1308, 17523.50, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1330, 1309, 43560.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1331, 1310, 154440.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1332, 1312, 81620.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1333, 1313, 193380.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1334, 1314, 113410.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1335, 1315, 57640.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1336, 1316, 93403.20, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1337, 1317, 162250.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1338, 1318, 29651.66, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1339, 1318, 29608.84, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1340, 1319, 70426.40, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1341, 1320, 97680.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1342, 1321, 54780.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1343, 1322, 70400.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1344, 1323, 40698.74, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1345, 1324, 71500.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1346, 1325, 23332.46, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1347, 1325, 12091.43, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1348, 1327, 17039.69, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1349, 1328, 97376.40, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1350, 1331, 72186.40, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1351, 1332, 49116.45, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1352, 1332, 42757.87, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1353, 1333, 43560.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1354, 1334, 27218.15, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1355, 1334, 10187.83, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1356, 1336, 71121.76, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1357, 1336, 26431.18, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1358, 1338, 88110.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1359, 1339, 31790.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1360, 1341, 84713.20, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1361, 1342, 52320.42, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1362, 1343, 64350.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1363, 1344, 40319.44, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1364, 1345, 94628.54, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1365, 1345, 26151.46, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1366, 1346, 65340.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1367, 1347, 134640.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1368, 1348, 39600.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1369, 1350, 105600.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1370, 1351, 88563.20, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1371, 1353, 112226.40, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1372, 1354, 31348.92, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1373, 1354, 4699.02, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1374, 1355, 72600.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1375, 1356, 79006.40, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1376, 1358, 109780.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1377, 1359, 23024.22, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1378, 1359, 13643.82, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1379, 1360, 132440.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1380, 1362, 31010.77, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1381, 1363, 53205.15, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1382, 1363, 55409.58, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1383, 1365, 19871.01, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1384, 1366, 48923.45, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1385, 1367, 72182.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1386, 1368, 107580.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1387, 1369, 52800.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1388, 1370, 28977.21, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1389, 1371, 41302.52, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1390, 1371, 15392.27, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1391, 1372, 56931.60, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1392, 1374, 29040.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1393, 1375, 64020.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1394, 1376, 48963.20, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1395, 1377, 140910.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1396, 1379, 114840.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1397, 1380, 46404.63, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1398, 1380, 13627.81, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1399, 1381, 112226.40, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1400, 1382, 24724.36, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1401, 1384, 62641.60, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1402, 1385, 70364.80, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1403, 1386, 22385.15, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1404, 1386, 22141.42, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1405, 1387, 26159.46, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1406, 1388, 57024.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1407, 1389, 65450.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1408, 1390, 39600.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1409, 1391, 31922.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1410, 1393, 51338.46, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1411, 1394, 15681.60, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1412, 1395, 68666.40, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1413, 1396, 57530.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1414, 1397, 25548.67, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1415, 1397, 9282.30, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1416, 1399, 40282.96, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1417, 1399, 9963.97, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1418, 1401, 32380.19, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1419, 1402, 69960.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1420, 1403, 9840.75, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1421, 1404, 39062.95, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1422, 1404, 17185.72, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1423, 1405, 35079.48, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1424, 1405, 9312.12, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1425, 1406, 78100.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1426, 1407, 49170.00, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1427, 1408, 93777.47, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1428, 1409, 53534.80, 'Card', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1429, 1410, 16938.39, 'Cash', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1430, 1410, 10398.32, 'Online', '2025-10-05 14:48:35.805126+05:30', NULL);
INSERT INTO public.payment VALUES (1432, 4, 38824.97, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1433, 30, 8969.27, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1434, 37, 40593.42, 'Card', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1435, 38, 16220.19, 'Card', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1436, 49, 2821.71, 'BankTransfer', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1437, 51, 40241.65, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1438, 8, 41713.78, 'BankTransfer', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1439, 111, 9437.71, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1440, 120, 6081.85, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1441, 139, 11181.30, 'BankTransfer', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1442, 144, 3752.23, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1443, 130, 23636.57, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1444, 221, 12821.44, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1445, 207, 13707.27, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1446, 171, 11856.57, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1447, 201, 7379.70, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1448, 223, 21152.32, 'BankTransfer', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1449, 181, 12117.14, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1450, 191, 10441.49, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1451, 211, 42770.87, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1452, 245, 29169.52, 'BankTransfer', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1453, 218, 2497.56, 'Card', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1454, 219, 2798.16, 'Card', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1455, 252, 31999.03, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1456, 276, 4293.09, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1457, 297, 10202.97, 'BankTransfer', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1458, 324, 20633.43, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1459, 283, 22738.87, 'BankTransfer', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1460, 319, 7652.89, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1461, 248, 10561.09, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1462, 267, 5042.03, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1463, 269, 6784.64, 'Card', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1464, 287, 14014.83, 'BankTransfer', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1465, 289, 555.21, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1466, 292, 3227.42, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1467, 307, 1582.37, 'BankTransfer', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1468, 310, 1148.14, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1469, 266, 455.17, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1470, 335, 5988.95, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1471, 350, 7572.89, 'Card', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1472, 360, 32558.66, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1473, 367, 6853.44, 'BankTransfer', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1474, 374, 6377.04, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1475, 390, 16580.12, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1476, 398, 6956.51, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1477, 382, 13320.50, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1478, 370, 564.41, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1479, 346, 3226.23, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1480, 395, 299.56, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1481, 409, 3263.43, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1482, 458, 22730.50, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1483, 487, 14077.99, 'BankTransfer', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1484, 440, 11649.65, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1485, 499, 21908.68, 'BankTransfer', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1486, 504, 19238.27, 'BankTransfer', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1487, 535, 34800.15, 'Card', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1488, 538, 4548.88, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1489, 544, 8401.29, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1490, 552, 28292.21, 'BankTransfer', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1491, 567, 51054.94, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1492, 570, 1751.81, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1493, 507, 6413.26, 'Card', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1494, 519, 5437.21, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1495, 532, 34011.92, 'BankTransfer', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1496, 539, 66733.81, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1497, 491, 8083.62, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1498, 547, 1382.50, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1499, 497, 107.49, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1500, 590, 35941.19, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1501, 631, 11072.38, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1502, 636, 40750.43, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1503, 639, 42108.26, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1504, 640, 1745.12, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1505, 649, 52027.14, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1506, 651, 6117.36, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1507, 578, 24515.34, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1508, 642, 21177.31, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1509, 671, 12258.80, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1510, 698, 6481.91, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1511, 700, 54167.96, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1512, 702, 2147.73, 'BankTransfer', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1513, 703, 10117.90, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1514, 662, 764.49, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1515, 691, 3383.75, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1516, 743, 1.13, 'BankTransfer', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1517, 790, 20001.98, 'Card', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1518, 800, 9019.32, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1519, 777, 4047.47, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1520, 741, 26179.72, 'BankTransfer', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1521, 796, 20882.04, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1522, 824, 12758.55, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1523, 826, 19939.91, 'BankTransfer', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1524, 827, 3208.86, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1525, 838, 91.11, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1526, 847, 6749.70, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1527, 860, 8331.78, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1528, 876, 20621.14, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1529, 895, 14437.10, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1530, 828, 18743.69, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1531, 866, 15634.31, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1532, 884, 3721.37, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1533, 817, 2006.00, 'BankTransfer', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1534, 857, 1976.15, 'Card', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1535, 864, 3937.93, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1536, 898, 14009.71, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1537, 926, 19370.58, 'BankTransfer', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1538, 930, 8591.70, 'Card', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1539, 935, 15629.94, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1540, 936, 15498.88, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1541, 942, 4616.28, 'Card', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1542, 950, 9176.07, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1543, 951, 26006.08, 'Card', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1544, 965, 47367.86, 'Card', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1545, 925, 2868.49, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1546, 917, 54513.53, 'Card', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1547, 948, 9691.36, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1548, 964, 12373.18, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1549, 968, 49471.92, 'Card', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1550, 1003, 2708.73, 'BankTransfer', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1551, 1004, 24181.38, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1552, 1008, 7096.94, 'Card', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1553, 1010, 60675.91, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1554, 1012, 4117.22, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1555, 1018, 18938.81, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1556, 1051, 9862.84, 'BankTransfer', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1557, 1055, 43476.38, 'BankTransfer', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1558, 978, 16517.72, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1559, 988, 55330.14, 'BankTransfer', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1560, 986, 29026.05, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1561, 999, 2054.53, 'BankTransfer', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1562, 1062, 3568.51, 'Card', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1563, 1065, 394.70, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1564, 1076, 5480.53, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1565, 1081, 47810.57, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1566, 1083, 42722.65, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1567, 1095, 14109.52, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1568, 1104, 24944.34, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1569, 1105, 16058.56, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1570, 1110, 17133.96, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1571, 1113, 18070.01, 'Card', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1572, 1126, 50553.98, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1573, 1131, 7475.47, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1574, 1077, 9251.01, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1575, 1097, 28634.02, 'Card', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1576, 1138, 5073.06, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1577, 1146, 29076.93, 'BankTransfer', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1578, 1153, 14032.22, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1579, 1165, 2158.11, 'BankTransfer', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1580, 1173, 2376.20, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1581, 1176, 36208.98, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1582, 1186, 29208.69, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1583, 1187, 11713.15, 'BankTransfer', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1584, 1193, 16980.17, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1585, 1196, 19595.86, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1586, 1201, 5956.90, 'Card', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1587, 1219, 7041.65, 'BankTransfer', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1588, 1220, 3444.72, 'Card', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1589, 1149, 11900.23, 'Card', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1590, 1215, 4153.32, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1591, 1221, 3253.08, 'BankTransfer', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1592, 1143, 18213.29, 'BankTransfer', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1593, 1228, 8895.61, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1594, 1240, 7104.65, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1595, 1278, 21843.05, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1596, 1291, 14600.14, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1597, 1261, 2949.31, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1598, 1276, 13313.72, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1599, 1302, 1113.64, 'Card', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1600, 1241, 11431.18, 'Card', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1601, 1318, 5698.35, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1602, 1323, 22585.99, 'BankTransfer', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1603, 1325, 6066.09, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1604, 1332, 19938.10, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1605, 1342, 26380.22, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1606, 1370, 13480.27, 'Card', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1607, 1371, 9251.95, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1608, 1380, 4456.71, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1609, 1303, 10624.99, 'BankTransfer', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1610, 1327, 5115.91, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1611, 1359, 11361.07, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1612, 1384, 10968.46, 'BankTransfer', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1613, 1399, 8687.72, 'Card', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1614, 1401, 8871.65, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1615, 129, 39434.44, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1616, 232, 3223.66, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1617, 327, 24320.33, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1618, 435, 35522.09, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1619, 462, 15417.79, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1620, 1386, 4616.40, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1621, 1387, 20752.03, 'Card', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1622, 156, 6481.86, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1623, 619, 8277.96, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1624, 896, 8246.04, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1625, 929, 13002.94, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1626, 932, 1405.26, 'BankTransfer', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1627, 605, 6098.81, 'Card', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1628, 593, 18115.67, 'BankTransfer', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1629, 1282, 9555.77, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1630, 1287, 10741.39, 'Card', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1631, 1308, 8803.91, 'BankTransfer', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1632, 1403, 6665.84, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1633, 304, 10020.68, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1634, 1132, 298.29, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1635, 436, 3887.52, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1636, 606, 10577.60, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1637, 1120, 5826.02, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1638, 1320, 101.93, 'Card', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1639, 1016, 703.74, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1640, 1299, 1605.73, 'Online', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1641, 237, 6837.61, 'Cash', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1642, 233, 1041.30, 'BankTransfer', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1643, 868, 3867.53, 'BankTransfer', '2025-10-05 15:02:17.08014+05:30', NULL);
INSERT INTO public.payment VALUES (1644, 123, 5000.00, 'Card', '2025-10-05 16:55:15.391748+05:30', NULL);
INSERT INTO public.payment VALUES (1645, 501, 20000.00, 'Online', '2025-10-05 17:39:10.469573+05:30', 'ADV-501-001');
INSERT INTO public.payment VALUES (1646, 1441, 8000.00, 'Card', '2025-10-07 12:52:29.221709+05:30', NULL);
INSERT INTO public.payment VALUES (1647, 1441, 5000.00, 'Card', '2025-10-07 12:59:03.067623+05:30', 'ADV2025-01');
INSERT INTO public.payment VALUES (1650, 1441, 6000.00, 'Cash', '2025-10-07 13:05:13.711961+05:30', 'CHECKIN-2025-02');
INSERT INTO public.payment VALUES (1651, 1441, 8000.00, 'Card', '2025-10-07 13:05:21.546271+05:30', NULL);
INSERT INTO public.payment VALUES (1654, 1441, 8000.00, 'Card', '2025-10-07 13:05:51.318828+05:30', NULL);
INSERT INTO public.payment VALUES (1656, 1441, 6000.00, 'Cash', '2025-10-07 13:08:15.954529+05:30', 'CHECKIN-2025-03');
INSERT INTO public.payment VALUES (1662, 1441, 6000.00, 'Cash', '2025-10-07 13:15:18.5651+05:30', 'CHECKIN');
INSERT INTO public.payment VALUES (1664, 1441, 6000.00, 'Cash', '2025-10-07 13:15:46.288797+05:30', 'CHECKIN-');
INSERT INTO public.payment VALUES (1665, 1441, 20000.00, 'Card', '2025-11-11 10:30:00+05:30', 'POS-98765');
INSERT INTO public.payment VALUES (1668, 1449, 5000.00, 'Cash', '2025-11-11 00:00:00+05:30', NULL);
INSERT INTO public.payment VALUES (1669, 1453, 5000.00, 'Card', '2025-10-07 20:12:53.650944+05:30', 'ADV-12345');
INSERT INTO public.payment VALUES (1670, 1457, 4000.00, 'Card', '2025-10-07 20:13:50.131468+05:30', 'ADV-12345');
INSERT INTO public.payment VALUES (1671, 1458, 4000.00, 'Card', '2025-10-07 20:19:55.782881+05:30', 'ADV-12345');


--
-- TOC entry 5419 (class 0 OID 17814)
-- Dependencies: 252
-- Data for Name: payment_adjustment; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.payment_adjustment VALUES (1, 501, 20000.00, 'refund', 'Advance refund after early cancellation', '2025-10-05 17:37:08.217675+05:30');
INSERT INTO public.payment_adjustment VALUES (2, 501, 20000.00, 'refund', 'Auto refund of advance on cancel', '2025-10-05 17:40:05.827774+05:30');
INSERT INTO public.payment_adjustment VALUES (3, 501, 20000.00, 'refund', 'Advance refunded to guest', '2025-10-05 17:40:47.592692+05:30');
INSERT INTO public.payment_adjustment VALUES (7, 1441, 300.00, 'manual_adjustment', NULL, '2025-10-07 18:24:10.645397+05:30');
INSERT INTO public.payment_adjustment VALUES (8, 1441, 500.00, 'refund', NULL, '2025-10-07 18:25:03.688498+05:30');
INSERT INTO public.payment_adjustment VALUES (9, 1441, 500.00, 'refund', NULL, '2025-10-07 18:31:44.18588+05:30');
INSERT INTO public.payment_adjustment VALUES (10, 1441, 500.00, 'refund', NULL, '2025-10-07 18:36:43.810438+05:30');
INSERT INTO public.payment_adjustment VALUES (11, 1441, 500.00, 'refund', NULL, '2025-10-07 18:47:24.64951+05:30');
INSERT INTO public.payment_adjustment VALUES (12, 1441, 500.00, 'refund', NULL, '2025-10-07 18:47:32.288052+05:30');
INSERT INTO public.payment_adjustment VALUES (13, 1441, 500.00, 'refund', NULL, '2025-10-07 18:48:04.094902+05:30');
INSERT INTO public.payment_adjustment VALUES (14, 1441, 500.00, 'refund', NULL, '2025-10-07 18:48:05.778295+05:30');


--
-- TOC entry 5409 (class 0 OID 16531)
-- Dependencies: 237
-- Data for Name: pre_booking; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.pre_booking VALUES (1, 1, 2, 'Online', '2025-10-20', '2025-10-23', NULL, NULL, '2025-10-06 23:26:52.053112+05:30');
INSERT INTO public.pre_booking VALUES (2, 2, 2, 'Online', '2025-10-20', '2025-10-23', NULL, NULL, '2025-10-06 23:26:52.053112+05:30');
INSERT INTO public.pre_booking VALUES (3, 3, 2, 'Online', '2025-10-20', '2025-10-23', NULL, NULL, '2025-10-06 23:26:52.053112+05:30');
INSERT INTO public.pre_booking VALUES (4, 1, 2, 'Phone', '2025-10-25', '2025-10-28', 20, NULL, '2025-10-06 23:26:52.053112+05:30');
INSERT INTO public.pre_booking VALUES (5, 1, 2, 'Phone', '2025-10-25', '2025-10-28', 40, NULL, '2025-10-06 23:26:52.053112+05:30');
INSERT INTO public.pre_booking VALUES (6, 1, 2, 'Phone', '2025-10-25', '2025-10-28', 60, NULL, '2025-10-06 23:26:52.053112+05:30');


--
-- TOC entry 5397 (class 0 OID 16464)
-- Dependencies: 225
-- Data for Name: room; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.room VALUES (1, 1, 4, '120', 'Available');
INSERT INTO public.room VALUES (2, 1, 4, '119', 'Available');
INSERT INTO public.room VALUES (3, 1, 4, '118', 'Available');
INSERT INTO public.room VALUES (4, 1, 3, '117', 'Available');
INSERT INTO public.room VALUES (5, 1, 3, '116', 'Available');
INSERT INTO public.room VALUES (6, 1, 3, '115', 'Available');
INSERT INTO public.room VALUES (7, 1, 3, '114', 'Available');
INSERT INTO public.room VALUES (8, 1, 3, '113', 'Available');
INSERT INTO public.room VALUES (9, 1, 2, '112', 'Available');
INSERT INTO public.room VALUES (10, 1, 2, '111', 'Available');
INSERT INTO public.room VALUES (12, 1, 2, '109', 'Available');
INSERT INTO public.room VALUES (13, 1, 2, '108', 'Available');
INSERT INTO public.room VALUES (14, 1, 2, '107', 'Available');
INSERT INTO public.room VALUES (15, 1, 2, '106', 'Available');
INSERT INTO public.room VALUES (16, 1, 1, '105', 'Available');
INSERT INTO public.room VALUES (17, 1, 1, '104', 'Available');
INSERT INTO public.room VALUES (18, 1, 1, '103', 'Available');
INSERT INTO public.room VALUES (19, 1, 1, '102', 'Available');
INSERT INTO public.room VALUES (20, 1, 1, '101', 'Available');
INSERT INTO public.room VALUES (21, 2, 4, '220', 'Available');
INSERT INTO public.room VALUES (22, 2, 4, '219', 'Available');
INSERT INTO public.room VALUES (23, 2, 4, '218', 'Available');
INSERT INTO public.room VALUES (24, 2, 3, '217', 'Available');
INSERT INTO public.room VALUES (25, 2, 3, '216', 'Available');
INSERT INTO public.room VALUES (26, 2, 3, '215', 'Available');
INSERT INTO public.room VALUES (27, 2, 3, '214', 'Available');
INSERT INTO public.room VALUES (28, 2, 3, '213', 'Available');
INSERT INTO public.room VALUES (29, 2, 2, '212', 'Available');
INSERT INTO public.room VALUES (30, 2, 2, '211', 'Available');
INSERT INTO public.room VALUES (32, 2, 2, '209', 'Available');
INSERT INTO public.room VALUES (33, 2, 2, '208', 'Available');
INSERT INTO public.room VALUES (34, 2, 2, '207', 'Available');
INSERT INTO public.room VALUES (35, 2, 2, '206', 'Available');
INSERT INTO public.room VALUES (36, 2, 1, '205', 'Available');
INSERT INTO public.room VALUES (37, 2, 1, '204', 'Available');
INSERT INTO public.room VALUES (38, 2, 1, '203', 'Available');
INSERT INTO public.room VALUES (39, 2, 1, '202', 'Available');
INSERT INTO public.room VALUES (40, 2, 1, '201', 'Available');
INSERT INTO public.room VALUES (41, 3, 4, '320', 'Available');
INSERT INTO public.room VALUES (42, 3, 4, '319', 'Available');
INSERT INTO public.room VALUES (43, 3, 4, '318', 'Available');
INSERT INTO public.room VALUES (44, 3, 3, '317', 'Available');
INSERT INTO public.room VALUES (45, 3, 3, '316', 'Available');
INSERT INTO public.room VALUES (46, 3, 3, '315', 'Available');
INSERT INTO public.room VALUES (47, 3, 3, '314', 'Available');
INSERT INTO public.room VALUES (48, 3, 3, '313', 'Available');
INSERT INTO public.room VALUES (49, 3, 2, '312', 'Available');
INSERT INTO public.room VALUES (50, 3, 2, '311', 'Available');
INSERT INTO public.room VALUES (52, 3, 2, '309', 'Available');
INSERT INTO public.room VALUES (53, 3, 2, '308', 'Available');
INSERT INTO public.room VALUES (54, 3, 2, '307', 'Available');
INSERT INTO public.room VALUES (55, 3, 2, '306', 'Available');
INSERT INTO public.room VALUES (56, 3, 1, '305', 'Available');
INSERT INTO public.room VALUES (57, 3, 1, '304', 'Available');
INSERT INTO public.room VALUES (58, 3, 1, '303', 'Available');
INSERT INTO public.room VALUES (59, 3, 1, '302', 'Available');
INSERT INTO public.room VALUES (60, 3, 1, '301', 'Available');
INSERT INTO public.room VALUES (11, 1, 2, '110', 'Maintenance');
INSERT INTO public.room VALUES (31, 2, 2, '210', 'Maintenance');
INSERT INTO public.room VALUES (51, 3, 2, '310', 'Maintenance');


--
-- TOC entry 5399 (class 0 OID 16473)
-- Dependencies: 227
-- Data for Name: room_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.room_type VALUES (1, 'Standard Single', 1, 12000.00, 'WiFi, TV, AC');
INSERT INTO public.room_type VALUES (2, 'Standard Double', 2, 18000.00, 'WiFi, TV, AC, Mini Fridge');
INSERT INTO public.room_type VALUES (3, 'Deluxe King', 2, 24000.00, 'WiFi, TV, AC, Mini Bar, Sea View');
INSERT INTO public.room_type VALUES (4, 'Suite', 4, 40000.00, 'WiFi, TV, AC, Mini Bar, Kitchenette, Balcony');


--
-- TOC entry 5413 (class 0 OID 16549)
-- Dependencies: 241
-- Data for Name: service_catalog; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.service_catalog VALUES (1, 'BRK', 'Breakfast Buffet', 'Food & Beverage', 2500.00, 0.00, true);
INSERT INTO public.service_catalog VALUES (2, 'DIN', 'Dinner (Set Menu)', 'Food & Beverage', 6000.00, 0.00, true);
INSERT INTO public.service_catalog VALUES (3, 'RMS', 'Room Service', 'Food & Beverage', 3500.00, 0.00, true);
INSERT INTO public.service_catalog VALUES (4, 'MIN', 'Minibar (per item)', 'Food & Beverage', 1800.00, 0.00, true);
INSERT INTO public.service_catalog VALUES (5, 'SPA', 'Spa Treatment (60m)', 'Wellness', 15000.00, 0.00, true);
INSERT INTO public.service_catalog VALUES (6, 'LND', 'Laundry (per piece)', 'Housekeeping', 600.00, 0.00, true);
INSERT INTO public.service_catalog VALUES (7, 'TRN', 'Airport Transfer', 'Transport', 12000.00, 0.00, true);


--
-- TOC entry 5415 (class 0 OID 16560)
-- Dependencies: 243
-- Data for Name: service_usage; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.service_usage VALUES (1, 1, 5, '2025-07-02', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2, 1, 1, '2025-07-02', 2, 2500.00);
INSERT INTO public.service_usage VALUES (3, 3, 6, '2025-07-12', 3, 600.00);
INSERT INTO public.service_usage VALUES (4, 3, 3, '2025-07-09', 3, 3500.00);
INSERT INTO public.service_usage VALUES (5, 4, 3, '2025-07-16', 2, 3500.00);
INSERT INTO public.service_usage VALUES (6, 5, 3, '2025-07-24', 2, 3500.00);
INSERT INTO public.service_usage VALUES (7, 5, 1, '2025-07-25', 4, 2500.00);
INSERT INTO public.service_usage VALUES (8, 5, 1, '2025-07-23', 1, 2500.00);
INSERT INTO public.service_usage VALUES (9, 5, 1, '2025-07-23', 2, 2500.00);
INSERT INTO public.service_usage VALUES (10, 6, 4, '2025-07-28', 1, 1800.00);
INSERT INTO public.service_usage VALUES (11, 6, 2, '2025-07-26', 2, 6000.00);
INSERT INTO public.service_usage VALUES (12, 6, 4, '2025-07-28', 2, 1800.00);
INSERT INTO public.service_usage VALUES (13, 7, 3, '2025-08-02', 1, 3500.00);
INSERT INTO public.service_usage VALUES (14, 8, 7, '2025-08-06', 2, 12000.00);
INSERT INTO public.service_usage VALUES (15, 8, 5, '2025-08-07', 3, 15000.00);
INSERT INTO public.service_usage VALUES (16, 10, 7, '2025-08-13', 2, 12000.00);
INSERT INTO public.service_usage VALUES (17, 10, 5, '2025-08-15', 4, 15000.00);
INSERT INTO public.service_usage VALUES (18, 10, 7, '2025-08-14', 4, 12000.00);
INSERT INTO public.service_usage VALUES (19, 10, 7, '2025-08-13', 4, 12000.00);
INSERT INTO public.service_usage VALUES (20, 13, 4, '2025-08-29', 3, 1800.00);
INSERT INTO public.service_usage VALUES (21, 15, 5, '2025-09-03', 1, 15000.00);
INSERT INTO public.service_usage VALUES (22, 15, 2, '2025-09-01', 2, 6000.00);
INSERT INTO public.service_usage VALUES (23, 15, 4, '2025-09-01', 1, 1800.00);
INSERT INTO public.service_usage VALUES (24, 17, 5, '2025-09-12', 3, 15000.00);
INSERT INTO public.service_usage VALUES (25, 17, 3, '2025-09-11', 2, 3500.00);
INSERT INTO public.service_usage VALUES (26, 17, 3, '2025-09-13', 3, 3500.00);
INSERT INTO public.service_usage VALUES (27, 17, 7, '2025-09-14', 1, 12000.00);
INSERT INTO public.service_usage VALUES (28, 19, 2, '2025-09-20', 1, 6000.00);
INSERT INTO public.service_usage VALUES (29, 19, 1, '2025-09-20', 4, 2500.00);
INSERT INTO public.service_usage VALUES (30, 19, 3, '2025-09-20', 3, 3500.00);
INSERT INTO public.service_usage VALUES (31, 19, 7, '2025-09-20', 3, 12000.00);
INSERT INTO public.service_usage VALUES (32, 20, 2, '2025-09-24', 1, 6000.00);
INSERT INTO public.service_usage VALUES (33, 21, 7, '2025-09-28', 4, 12000.00);
INSERT INTO public.service_usage VALUES (34, 21, 4, '2025-09-29', 2, 1800.00);
INSERT INTO public.service_usage VALUES (35, 23, 3, '2025-07-04', 4, 3500.00);
INSERT INTO public.service_usage VALUES (36, 23, 7, '2025-07-07', 2, 12000.00);
INSERT INTO public.service_usage VALUES (37, 24, 2, '2025-07-11', 3, 6000.00);
INSERT INTO public.service_usage VALUES (38, 24, 5, '2025-07-10', 2, 15000.00);
INSERT INTO public.service_usage VALUES (39, 25, 6, '2025-07-13', 2, 600.00);
INSERT INTO public.service_usage VALUES (40, 25, 4, '2025-07-13', 2, 1800.00);
INSERT INTO public.service_usage VALUES (41, 25, 2, '2025-07-14', 3, 6000.00);
INSERT INTO public.service_usage VALUES (42, 25, 1, '2025-07-15', 2, 2500.00);
INSERT INTO public.service_usage VALUES (43, 28, 6, '2025-07-25', 2, 600.00);
INSERT INTO public.service_usage VALUES (44, 28, 5, '2025-07-26', 2, 15000.00);
INSERT INTO public.service_usage VALUES (45, 28, 1, '2025-07-26', 1, 2500.00);
INSERT INTO public.service_usage VALUES (46, 29, 4, '2025-07-28', 2, 1800.00);
INSERT INTO public.service_usage VALUES (47, 31, 2, '2025-08-04', 3, 6000.00);
INSERT INTO public.service_usage VALUES (48, 31, 2, '2025-08-04', 1, 6000.00);
INSERT INTO public.service_usage VALUES (49, 32, 2, '2025-08-06', 3, 6000.00);
INSERT INTO public.service_usage VALUES (50, 32, 4, '2025-08-08', 3, 1800.00);
INSERT INTO public.service_usage VALUES (51, 33, 4, '2025-08-11', 4, 1800.00);
INSERT INTO public.service_usage VALUES (52, 33, 3, '2025-08-12', 3, 3500.00);
INSERT INTO public.service_usage VALUES (53, 33, 2, '2025-08-12', 2, 6000.00);
INSERT INTO public.service_usage VALUES (54, 34, 7, '2025-08-15', 3, 12000.00);
INSERT INTO public.service_usage VALUES (55, 34, 5, '2025-08-15', 2, 15000.00);
INSERT INTO public.service_usage VALUES (56, 34, 1, '2025-08-13', 3, 2500.00);
INSERT INTO public.service_usage VALUES (57, 35, 1, '2025-08-20', 1, 2500.00);
INSERT INTO public.service_usage VALUES (58, 35, 4, '2025-08-20', 2, 1800.00);
INSERT INTO public.service_usage VALUES (59, 37, 5, '2025-08-26', 2, 15000.00);
INSERT INTO public.service_usage VALUES (60, 38, 1, '2025-09-01', 2, 2500.00);
INSERT INTO public.service_usage VALUES (61, 38, 1, '2025-08-31', 2, 2500.00);
INSERT INTO public.service_usage VALUES (62, 39, 7, '2025-09-05', 3, 12000.00);
INSERT INTO public.service_usage VALUES (63, 39, 4, '2025-09-05', 3, 1800.00);
INSERT INTO public.service_usage VALUES (64, 39, 7, '2025-09-04', 2, 12000.00);
INSERT INTO public.service_usage VALUES (65, 40, 2, '2025-09-09', 3, 6000.00);
INSERT INTO public.service_usage VALUES (66, 41, 1, '2025-09-12', 1, 2500.00);
INSERT INTO public.service_usage VALUES (67, 41, 2, '2025-09-13', 2, 6000.00);
INSERT INTO public.service_usage VALUES (68, 41, 5, '2025-09-14', 2, 15000.00);
INSERT INTO public.service_usage VALUES (69, 42, 5, '2025-09-17', 3, 15000.00);
INSERT INTO public.service_usage VALUES (70, 42, 5, '2025-09-17', 1, 15000.00);
INSERT INTO public.service_usage VALUES (71, 43, 3, '2025-09-19', 2, 3500.00);
INSERT INTO public.service_usage VALUES (72, 43, 6, '2025-09-19', 2, 600.00);
INSERT INTO public.service_usage VALUES (73, 43, 5, '2025-09-19', 3, 15000.00);
INSERT INTO public.service_usage VALUES (74, 43, 7, '2025-09-20', 3, 12000.00);
INSERT INTO public.service_usage VALUES (75, 44, 5, '2025-09-23', 4, 15000.00);
INSERT INTO public.service_usage VALUES (76, 44, 5, '2025-09-23', 4, 15000.00);
INSERT INTO public.service_usage VALUES (77, 44, 4, '2025-09-23', 1, 1800.00);
INSERT INTO public.service_usage VALUES (78, 44, 7, '2025-09-24', 3, 12000.00);
INSERT INTO public.service_usage VALUES (79, 45, 3, '2025-09-27', 4, 3500.00);
INSERT INTO public.service_usage VALUES (80, 45, 5, '2025-09-26', 3, 15000.00);
INSERT INTO public.service_usage VALUES (81, 46, 5, '2025-10-02', 2, 15000.00);
INSERT INTO public.service_usage VALUES (82, 46, 6, '2025-10-01', 4, 600.00);
INSERT INTO public.service_usage VALUES (83, 46, 4, '2025-10-01', 3, 1800.00);
INSERT INTO public.service_usage VALUES (84, 48, 5, '2025-07-06', 4, 15000.00);
INSERT INTO public.service_usage VALUES (85, 48, 7, '2025-07-07', 3, 12000.00);
INSERT INTO public.service_usage VALUES (86, 49, 4, '2025-07-10', 1, 1800.00);
INSERT INTO public.service_usage VALUES (87, 49, 3, '2025-07-10', 1, 3500.00);
INSERT INTO public.service_usage VALUES (88, 49, 5, '2025-07-10', 1, 15000.00);
INSERT INTO public.service_usage VALUES (89, 50, 3, '2025-07-13', 3, 3500.00);
INSERT INTO public.service_usage VALUES (90, 50, 3, '2025-07-13', 4, 3500.00);
INSERT INTO public.service_usage VALUES (91, 50, 7, '2025-07-14', 1, 12000.00);
INSERT INTO public.service_usage VALUES (92, 50, 4, '2025-07-12', 4, 1800.00);
INSERT INTO public.service_usage VALUES (93, 51, 1, '2025-07-16', 4, 2500.00);
INSERT INTO public.service_usage VALUES (94, 51, 2, '2025-07-15', 4, 6000.00);
INSERT INTO public.service_usage VALUES (95, 52, 7, '2025-07-21', 3, 12000.00);
INSERT INTO public.service_usage VALUES (96, 53, 3, '2025-07-24', 2, 3500.00);
INSERT INTO public.service_usage VALUES (97, 54, 6, '2025-07-28', 1, 600.00);
INSERT INTO public.service_usage VALUES (98, 54, 5, '2025-07-28', 2, 15000.00);
INSERT INTO public.service_usage VALUES (99, 54, 4, '2025-07-29', 4, 1800.00);
INSERT INTO public.service_usage VALUES (100, 55, 2, '2025-08-03', 1, 6000.00);
INSERT INTO public.service_usage VALUES (101, 56, 1, '2025-08-06', 2, 2500.00);
INSERT INTO public.service_usage VALUES (102, 56, 7, '2025-08-06', 4, 12000.00);
INSERT INTO public.service_usage VALUES (103, 57, 6, '2025-08-08', 2, 600.00);
INSERT INTO public.service_usage VALUES (104, 58, 3, '2025-08-14', 3, 3500.00);
INSERT INTO public.service_usage VALUES (105, 58, 1, '2025-08-13', 3, 2500.00);
INSERT INTO public.service_usage VALUES (106, 60, 7, '2025-08-23', 3, 12000.00);
INSERT INTO public.service_usage VALUES (107, 60, 1, '2025-08-23', 2, 2500.00);
INSERT INTO public.service_usage VALUES (108, 60, 6, '2025-08-22', 4, 600.00);
INSERT INTO public.service_usage VALUES (109, 63, 4, '2025-09-03', 3, 1800.00);
INSERT INTO public.service_usage VALUES (110, 63, 3, '2025-09-04', 3, 3500.00);
INSERT INTO public.service_usage VALUES (111, 63, 5, '2025-09-04', 3, 15000.00);
INSERT INTO public.service_usage VALUES (112, 63, 5, '2025-09-03', 4, 15000.00);
INSERT INTO public.service_usage VALUES (113, 64, 4, '2025-09-09', 3, 1800.00);
INSERT INTO public.service_usage VALUES (114, 64, 4, '2025-09-06', 4, 1800.00);
INSERT INTO public.service_usage VALUES (115, 65, 1, '2025-09-12', 3, 2500.00);
INSERT INTO public.service_usage VALUES (116, 65, 3, '2025-09-10', 3, 3500.00);
INSERT INTO public.service_usage VALUES (117, 65, 6, '2025-09-13', 3, 600.00);
INSERT INTO public.service_usage VALUES (118, 66, 7, '2025-09-17', 4, 12000.00);
INSERT INTO public.service_usage VALUES (119, 67, 3, '2025-09-23', 2, 3500.00);
INSERT INTO public.service_usage VALUES (120, 67, 7, '2025-09-23', 1, 12000.00);
INSERT INTO public.service_usage VALUES (121, 68, 3, '2025-09-26', 1, 3500.00);
INSERT INTO public.service_usage VALUES (122, 68, 5, '2025-09-26', 2, 15000.00);
INSERT INTO public.service_usage VALUES (123, 68, 7, '2025-09-26', 2, 12000.00);
INSERT INTO public.service_usage VALUES (124, 69, 3, '2025-09-30', 4, 3500.00);
INSERT INTO public.service_usage VALUES (125, 69, 5, '2025-09-28', 2, 15000.00);
INSERT INTO public.service_usage VALUES (126, 69, 1, '2025-09-29', 1, 2500.00);
INSERT INTO public.service_usage VALUES (127, 69, 5, '2025-09-30', 4, 15000.00);
INSERT INTO public.service_usage VALUES (128, 71, 3, '2025-07-06', 3, 3500.00);
INSERT INTO public.service_usage VALUES (129, 71, 5, '2025-07-06', 2, 15000.00);
INSERT INTO public.service_usage VALUES (130, 71, 5, '2025-07-05', 4, 15000.00);
INSERT INTO public.service_usage VALUES (131, 72, 6, '2025-07-10', 3, 600.00);
INSERT INTO public.service_usage VALUES (132, 72, 4, '2025-07-10', 2, 1800.00);
INSERT INTO public.service_usage VALUES (133, 72, 5, '2025-07-10', 1, 15000.00);
INSERT INTO public.service_usage VALUES (134, 73, 7, '2025-07-13', 2, 12000.00);
INSERT INTO public.service_usage VALUES (135, 73, 2, '2025-07-12', 2, 6000.00);
INSERT INTO public.service_usage VALUES (136, 73, 5, '2025-07-13', 4, 15000.00);
INSERT INTO public.service_usage VALUES (137, 74, 3, '2025-07-14', 3, 3500.00);
INSERT INTO public.service_usage VALUES (138, 74, 4, '2025-07-14', 3, 1800.00);
INSERT INTO public.service_usage VALUES (139, 74, 7, '2025-07-14', 4, 12000.00);
INSERT INTO public.service_usage VALUES (140, 74, 5, '2025-07-14', 2, 15000.00);
INSERT INTO public.service_usage VALUES (141, 75, 7, '2025-07-17', 3, 12000.00);
INSERT INTO public.service_usage VALUES (142, 75, 6, '2025-07-17', 1, 600.00);
INSERT INTO public.service_usage VALUES (143, 75, 4, '2025-07-16', 1, 1800.00);
INSERT INTO public.service_usage VALUES (144, 75, 3, '2025-07-17', 4, 3500.00);
INSERT INTO public.service_usage VALUES (145, 76, 4, '2025-07-19', 2, 1800.00);
INSERT INTO public.service_usage VALUES (146, 76, 4, '2025-07-19', 2, 1800.00);
INSERT INTO public.service_usage VALUES (147, 77, 1, '2025-07-22', 4, 2500.00);
INSERT INTO public.service_usage VALUES (148, 79, 4, '2025-07-31', 2, 1800.00);
INSERT INTO public.service_usage VALUES (149, 79, 3, '2025-07-31', 2, 3500.00);
INSERT INTO public.service_usage VALUES (150, 79, 5, '2025-07-31', 1, 15000.00);
INSERT INTO public.service_usage VALUES (151, 79, 3, '2025-07-31', 2, 3500.00);
INSERT INTO public.service_usage VALUES (152, 80, 1, '2025-08-04', 2, 2500.00);
INSERT INTO public.service_usage VALUES (153, 80, 4, '2025-08-04', 4, 1800.00);
INSERT INTO public.service_usage VALUES (154, 80, 7, '2025-08-05', 2, 12000.00);
INSERT INTO public.service_usage VALUES (155, 81, 5, '2025-08-09', 4, 15000.00);
INSERT INTO public.service_usage VALUES (156, 81, 6, '2025-08-09', 4, 600.00);
INSERT INTO public.service_usage VALUES (157, 82, 4, '2025-08-13', 2, 1800.00);
INSERT INTO public.service_usage VALUES (158, 83, 4, '2025-08-18', 2, 1800.00);
INSERT INTO public.service_usage VALUES (159, 83, 6, '2025-08-17', 3, 600.00);
INSERT INTO public.service_usage VALUES (160, 83, 1, '2025-08-17', 4, 2500.00);
INSERT INTO public.service_usage VALUES (161, 83, 1, '2025-08-17', 1, 2500.00);
INSERT INTO public.service_usage VALUES (162, 85, 7, '2025-08-24', 4, 12000.00);
INSERT INTO public.service_usage VALUES (163, 85, 6, '2025-08-24', 4, 600.00);
INSERT INTO public.service_usage VALUES (164, 85, 4, '2025-08-24', 3, 1800.00);
INSERT INTO public.service_usage VALUES (165, 86, 6, '2025-08-27', 4, 600.00);
INSERT INTO public.service_usage VALUES (166, 86, 4, '2025-08-25', 2, 1800.00);
INSERT INTO public.service_usage VALUES (167, 86, 1, '2025-08-29', 3, 2500.00);
INSERT INTO public.service_usage VALUES (168, 86, 2, '2025-08-29', 1, 6000.00);
INSERT INTO public.service_usage VALUES (169, 87, 7, '2025-09-01', 4, 12000.00);
INSERT INTO public.service_usage VALUES (170, 87, 5, '2025-09-01', 2, 15000.00);
INSERT INTO public.service_usage VALUES (171, 88, 5, '2025-09-05', 2, 15000.00);
INSERT INTO public.service_usage VALUES (172, 88, 3, '2025-09-05', 2, 3500.00);
INSERT INTO public.service_usage VALUES (173, 88, 4, '2025-09-07', 3, 1800.00);
INSERT INTO public.service_usage VALUES (174, 89, 5, '2025-09-11', 2, 15000.00);
INSERT INTO public.service_usage VALUES (175, 89, 1, '2025-09-10', 2, 2500.00);
INSERT INTO public.service_usage VALUES (176, 90, 1, '2025-09-18', 4, 2500.00);
INSERT INTO public.service_usage VALUES (177, 90, 5, '2025-09-15', 1, 15000.00);
INSERT INTO public.service_usage VALUES (178, 91, 4, '2025-09-19', 2, 1800.00);
INSERT INTO public.service_usage VALUES (179, 91, 4, '2025-09-19', 3, 1800.00);
INSERT INTO public.service_usage VALUES (180, 91, 5, '2025-09-19', 1, 15000.00);
INSERT INTO public.service_usage VALUES (181, 91, 5, '2025-09-19', 1, 15000.00);
INSERT INTO public.service_usage VALUES (182, 92, 1, '2025-09-25', 3, 2500.00);
INSERT INTO public.service_usage VALUES (183, 92, 2, '2025-09-22', 2, 6000.00);
INSERT INTO public.service_usage VALUES (184, 92, 5, '2025-09-26', 3, 15000.00);
INSERT INTO public.service_usage VALUES (185, 93, 5, '2025-09-28', 4, 15000.00);
INSERT INTO public.service_usage VALUES (186, 93, 3, '2025-09-28', 3, 3500.00);
INSERT INTO public.service_usage VALUES (187, 94, 4, '2025-07-01', 3, 1800.00);
INSERT INTO public.service_usage VALUES (188, 95, 7, '2025-07-06', 3, 12000.00);
INSERT INTO public.service_usage VALUES (189, 95, 1, '2025-07-07', 2, 2500.00);
INSERT INTO public.service_usage VALUES (190, 95, 6, '2025-07-06', 1, 600.00);
INSERT INTO public.service_usage VALUES (191, 96, 5, '2025-07-09', 3, 15000.00);
INSERT INTO public.service_usage VALUES (192, 96, 4, '2025-07-10', 2, 1800.00);
INSERT INTO public.service_usage VALUES (193, 97, 4, '2025-07-14', 2, 1800.00);
INSERT INTO public.service_usage VALUES (194, 97, 2, '2025-07-13', 2, 6000.00);
INSERT INTO public.service_usage VALUES (195, 97, 4, '2025-07-13', 2, 1800.00);
INSERT INTO public.service_usage VALUES (196, 98, 3, '2025-07-19', 2, 3500.00);
INSERT INTO public.service_usage VALUES (197, 98, 7, '2025-07-19', 1, 12000.00);
INSERT INTO public.service_usage VALUES (198, 98, 1, '2025-07-19', 3, 2500.00);
INSERT INTO public.service_usage VALUES (199, 98, 2, '2025-07-19', 3, 6000.00);
INSERT INTO public.service_usage VALUES (200, 99, 4, '2025-07-21', 2, 1800.00);
INSERT INTO public.service_usage VALUES (201, 99, 5, '2025-07-21', 4, 15000.00);
INSERT INTO public.service_usage VALUES (202, 99, 2, '2025-07-21', 3, 6000.00);
INSERT INTO public.service_usage VALUES (203, 100, 7, '2025-07-23', 3, 12000.00);
INSERT INTO public.service_usage VALUES (204, 100, 7, '2025-07-23', 3, 12000.00);
INSERT INTO public.service_usage VALUES (205, 101, 7, '2025-07-25', 1, 12000.00);
INSERT INTO public.service_usage VALUES (206, 101, 2, '2025-07-25', 1, 6000.00);
INSERT INTO public.service_usage VALUES (207, 101, 7, '2025-07-26', 2, 12000.00);
INSERT INTO public.service_usage VALUES (208, 102, 2, '2025-07-30', 3, 6000.00);
INSERT INTO public.service_usage VALUES (209, 102, 4, '2025-07-31', 4, 1800.00);
INSERT INTO public.service_usage VALUES (210, 102, 1, '2025-07-31', 3, 2500.00);
INSERT INTO public.service_usage VALUES (211, 103, 7, '2025-08-06', 3, 12000.00);
INSERT INTO public.service_usage VALUES (212, 104, 4, '2025-08-13', 2, 1800.00);
INSERT INTO public.service_usage VALUES (213, 104, 6, '2025-08-10', 3, 600.00);
INSERT INTO public.service_usage VALUES (214, 104, 1, '2025-08-12', 4, 2500.00);
INSERT INTO public.service_usage VALUES (215, 105, 6, '2025-08-17', 4, 600.00);
INSERT INTO public.service_usage VALUES (216, 105, 1, '2025-08-17', 1, 2500.00);
INSERT INTO public.service_usage VALUES (217, 106, 2, '2025-08-20', 3, 6000.00);
INSERT INTO public.service_usage VALUES (218, 106, 6, '2025-08-19', 3, 600.00);
INSERT INTO public.service_usage VALUES (219, 106, 2, '2025-08-19', 2, 6000.00);
INSERT INTO public.service_usage VALUES (220, 108, 7, '2025-08-30', 4, 12000.00);
INSERT INTO public.service_usage VALUES (221, 108, 2, '2025-08-27', 4, 6000.00);
INSERT INTO public.service_usage VALUES (222, 108, 7, '2025-08-27', 2, 12000.00);
INSERT INTO public.service_usage VALUES (223, 109, 5, '2025-08-31', 2, 15000.00);
INSERT INTO public.service_usage VALUES (224, 109, 5, '2025-08-31', 1, 15000.00);
INSERT INTO public.service_usage VALUES (225, 110, 2, '2025-09-03', 3, 6000.00);
INSERT INTO public.service_usage VALUES (226, 110, 4, '2025-09-03', 2, 1800.00);
INSERT INTO public.service_usage VALUES (227, 110, 5, '2025-09-04', 1, 15000.00);
INSERT INTO public.service_usage VALUES (228, 111, 6, '2025-09-07', 2, 600.00);
INSERT INTO public.service_usage VALUES (229, 112, 5, '2025-09-11', 3, 15000.00);
INSERT INTO public.service_usage VALUES (230, 112, 1, '2025-09-11', 4, 2500.00);
INSERT INTO public.service_usage VALUES (231, 112, 7, '2025-09-11', 2, 12000.00);
INSERT INTO public.service_usage VALUES (232, 113, 1, '2025-09-13', 1, 2500.00);
INSERT INTO public.service_usage VALUES (233, 113, 7, '2025-09-14', 1, 12000.00);
INSERT INTO public.service_usage VALUES (234, 113, 1, '2025-09-14', 3, 2500.00);
INSERT INTO public.service_usage VALUES (235, 115, 6, '2025-09-23', 3, 600.00);
INSERT INTO public.service_usage VALUES (236, 115, 7, '2025-09-24', 2, 12000.00);
INSERT INTO public.service_usage VALUES (237, 115, 2, '2025-09-24', 1, 6000.00);
INSERT INTO public.service_usage VALUES (238, 115, 7, '2025-09-23', 3, 12000.00);
INSERT INTO public.service_usage VALUES (239, 117, 2, '2025-07-02', 4, 6000.00);
INSERT INTO public.service_usage VALUES (240, 117, 5, '2025-07-02', 1, 15000.00);
INSERT INTO public.service_usage VALUES (241, 117, 7, '2025-07-02', 3, 12000.00);
INSERT INTO public.service_usage VALUES (242, 119, 5, '2025-07-09', 2, 15000.00);
INSERT INTO public.service_usage VALUES (243, 119, 3, '2025-07-09', 4, 3500.00);
INSERT INTO public.service_usage VALUES (244, 119, 3, '2025-07-07', 1, 3500.00);
INSERT INTO public.service_usage VALUES (245, 120, 6, '2025-07-10', 1, 600.00);
INSERT INTO public.service_usage VALUES (246, 120, 3, '2025-07-10', 1, 3500.00);
INSERT INTO public.service_usage VALUES (247, 122, 1, '2025-07-21', 1, 2500.00);
INSERT INTO public.service_usage VALUES (248, 122, 7, '2025-07-19', 1, 12000.00);
INSERT INTO public.service_usage VALUES (249, 122, 2, '2025-07-20', 3, 6000.00);
INSERT INTO public.service_usage VALUES (250, 122, 2, '2025-07-19', 3, 6000.00);
INSERT INTO public.service_usage VALUES (251, 123, 5, '2025-07-28', 3, 15000.00);
INSERT INTO public.service_usage VALUES (252, 124, 5, '2025-07-30', 2, 15000.00);
INSERT INTO public.service_usage VALUES (253, 125, 4, '2025-07-31', 2, 1800.00);
INSERT INTO public.service_usage VALUES (254, 126, 3, '2025-08-02', 1, 3500.00);
INSERT INTO public.service_usage VALUES (255, 126, 7, '2025-08-02', 3, 12000.00);
INSERT INTO public.service_usage VALUES (256, 126, 1, '2025-08-03', 4, 2500.00);
INSERT INTO public.service_usage VALUES (257, 127, 6, '2025-08-06', 2, 600.00);
INSERT INTO public.service_usage VALUES (258, 128, 7, '2025-08-09', 1, 12000.00);
INSERT INTO public.service_usage VALUES (259, 128, 6, '2025-08-11', 1, 600.00);
INSERT INTO public.service_usage VALUES (260, 128, 5, '2025-08-09', 1, 15000.00);
INSERT INTO public.service_usage VALUES (261, 129, 1, '2025-08-15', 3, 2500.00);
INSERT INTO public.service_usage VALUES (262, 129, 3, '2025-08-15', 3, 3500.00);
INSERT INTO public.service_usage VALUES (263, 129, 7, '2025-08-14', 2, 12000.00);
INSERT INTO public.service_usage VALUES (264, 129, 7, '2025-08-14', 3, 12000.00);
INSERT INTO public.service_usage VALUES (265, 130, 5, '2025-08-19', 3, 15000.00);
INSERT INTO public.service_usage VALUES (266, 130, 6, '2025-08-20', 2, 600.00);
INSERT INTO public.service_usage VALUES (267, 132, 7, '2025-08-26', 4, 12000.00);
INSERT INTO public.service_usage VALUES (268, 133, 5, '2025-08-29', 1, 15000.00);
INSERT INTO public.service_usage VALUES (269, 135, 5, '2025-09-05', 3, 15000.00);
INSERT INTO public.service_usage VALUES (270, 135, 3, '2025-09-05', 2, 3500.00);
INSERT INTO public.service_usage VALUES (271, 135, 3, '2025-09-04', 3, 3500.00);
INSERT INTO public.service_usage VALUES (272, 135, 1, '2025-09-05', 1, 2500.00);
INSERT INTO public.service_usage VALUES (273, 136, 6, '2025-09-07', 2, 600.00);
INSERT INTO public.service_usage VALUES (274, 136, 4, '2025-09-07', 3, 1800.00);
INSERT INTO public.service_usage VALUES (275, 136, 3, '2025-09-07', 2, 3500.00);
INSERT INTO public.service_usage VALUES (276, 136, 7, '2025-09-08', 3, 12000.00);
INSERT INTO public.service_usage VALUES (277, 137, 6, '2025-09-11', 1, 600.00);
INSERT INTO public.service_usage VALUES (278, 137, 2, '2025-09-11', 2, 6000.00);
INSERT INTO public.service_usage VALUES (279, 137, 1, '2025-09-11', 2, 2500.00);
INSERT INTO public.service_usage VALUES (280, 137, 5, '2025-09-11', 2, 15000.00);
INSERT INTO public.service_usage VALUES (281, 138, 4, '2025-09-12', 4, 1800.00);
INSERT INTO public.service_usage VALUES (282, 138, 7, '2025-09-12', 3, 12000.00);
INSERT INTO public.service_usage VALUES (283, 138, 6, '2025-09-12', 3, 600.00);
INSERT INTO public.service_usage VALUES (284, 140, 1, '2025-09-22', 3, 2500.00);
INSERT INTO public.service_usage VALUES (285, 141, 7, '2025-09-27', 2, 12000.00);
INSERT INTO public.service_usage VALUES (286, 141, 2, '2025-09-27', 3, 6000.00);
INSERT INTO public.service_usage VALUES (287, 141, 7, '2025-09-26', 2, 12000.00);
INSERT INTO public.service_usage VALUES (288, 143, 1, '2025-10-01', 2, 2500.00);
INSERT INTO public.service_usage VALUES (289, 143, 4, '2025-10-01', 2, 1800.00);
INSERT INTO public.service_usage VALUES (290, 143, 1, '2025-10-02', 3, 2500.00);
INSERT INTO public.service_usage VALUES (291, 144, 6, '2025-07-02', 2, 600.00);
INSERT INTO public.service_usage VALUES (292, 145, 2, '2025-07-06', 4, 6000.00);
INSERT INTO public.service_usage VALUES (293, 146, 6, '2025-07-12', 4, 600.00);
INSERT INTO public.service_usage VALUES (294, 146, 3, '2025-07-12', 4, 3500.00);
INSERT INTO public.service_usage VALUES (295, 146, 6, '2025-07-12', 2, 600.00);
INSERT INTO public.service_usage VALUES (296, 147, 1, '2025-07-15', 4, 2500.00);
INSERT INTO public.service_usage VALUES (297, 148, 3, '2025-07-18', 3, 3500.00);
INSERT INTO public.service_usage VALUES (298, 148, 4, '2025-07-21', 3, 1800.00);
INSERT INTO public.service_usage VALUES (299, 149, 3, '2025-07-24', 1, 3500.00);
INSERT INTO public.service_usage VALUES (300, 150, 7, '2025-08-01', 1, 12000.00);
INSERT INTO public.service_usage VALUES (301, 150, 1, '2025-07-31', 2, 2500.00);
INSERT INTO public.service_usage VALUES (302, 150, 5, '2025-07-30', 1, 15000.00);
INSERT INTO public.service_usage VALUES (303, 151, 5, '2025-08-04', 4, 15000.00);
INSERT INTO public.service_usage VALUES (304, 151, 3, '2025-08-04', 3, 3500.00);
INSERT INTO public.service_usage VALUES (305, 151, 4, '2025-08-04', 2, 1800.00);
INSERT INTO public.service_usage VALUES (306, 153, 5, '2025-08-11', 4, 15000.00);
INSERT INTO public.service_usage VALUES (307, 153, 2, '2025-08-11', 4, 6000.00);
INSERT INTO public.service_usage VALUES (308, 153, 6, '2025-08-11', 2, 600.00);
INSERT INTO public.service_usage VALUES (309, 154, 1, '2025-08-12', 4, 2500.00);
INSERT INTO public.service_usage VALUES (310, 154, 2, '2025-08-12', 1, 6000.00);
INSERT INTO public.service_usage VALUES (311, 154, 7, '2025-08-12', 3, 12000.00);
INSERT INTO public.service_usage VALUES (312, 154, 5, '2025-08-12', 2, 15000.00);
INSERT INTO public.service_usage VALUES (313, 155, 5, '2025-08-13', 3, 15000.00);
INSERT INTO public.service_usage VALUES (314, 155, 4, '2025-08-14', 2, 1800.00);
INSERT INTO public.service_usage VALUES (315, 155, 4, '2025-08-14', 3, 1800.00);
INSERT INTO public.service_usage VALUES (316, 155, 6, '2025-08-14', 3, 600.00);
INSERT INTO public.service_usage VALUES (317, 157, 2, '2025-08-22', 3, 6000.00);
INSERT INTO public.service_usage VALUES (318, 157, 7, '2025-08-20', 4, 12000.00);
INSERT INTO public.service_usage VALUES (319, 157, 2, '2025-08-21', 2, 6000.00);
INSERT INTO public.service_usage VALUES (320, 157, 2, '2025-08-20', 3, 6000.00);
INSERT INTO public.service_usage VALUES (321, 158, 4, '2025-08-24', 4, 1800.00);
INSERT INTO public.service_usage VALUES (322, 158, 1, '2025-08-25', 3, 2500.00);
INSERT INTO public.service_usage VALUES (323, 158, 7, '2025-08-24', 1, 12000.00);
INSERT INTO public.service_usage VALUES (324, 159, 1, '2025-08-28', 1, 2500.00);
INSERT INTO public.service_usage VALUES (325, 159, 4, '2025-08-27', 2, 1800.00);
INSERT INTO public.service_usage VALUES (326, 160, 5, '2025-09-01', 1, 15000.00);
INSERT INTO public.service_usage VALUES (327, 161, 6, '2025-09-07', 3, 600.00);
INSERT INTO public.service_usage VALUES (328, 161, 7, '2025-09-08', 2, 12000.00);
INSERT INTO public.service_usage VALUES (329, 162, 3, '2025-09-14', 2, 3500.00);
INSERT INTO public.service_usage VALUES (330, 162, 1, '2025-09-12', 2, 2500.00);
INSERT INTO public.service_usage VALUES (331, 162, 3, '2025-09-14', 3, 3500.00);
INSERT INTO public.service_usage VALUES (332, 163, 5, '2025-09-19', 2, 15000.00);
INSERT INTO public.service_usage VALUES (333, 163, 4, '2025-09-21', 4, 1800.00);
INSERT INTO public.service_usage VALUES (334, 163, 5, '2025-09-20', 2, 15000.00);
INSERT INTO public.service_usage VALUES (335, 164, 7, '2025-09-23', 2, 12000.00);
INSERT INTO public.service_usage VALUES (336, 165, 2, '2025-09-26', 3, 6000.00);
INSERT INTO public.service_usage VALUES (337, 165, 1, '2025-09-27', 3, 2500.00);
INSERT INTO public.service_usage VALUES (338, 165, 4, '2025-09-28', 1, 1800.00);
INSERT INTO public.service_usage VALUES (339, 166, 7, '2025-09-30', 2, 12000.00);
INSERT INTO public.service_usage VALUES (340, 166, 4, '2025-10-02', 1, 1800.00);
INSERT INTO public.service_usage VALUES (341, 168, 5, '2025-07-06', 1, 15000.00);
INSERT INTO public.service_usage VALUES (342, 168, 2, '2025-07-08', 2, 6000.00);
INSERT INTO public.service_usage VALUES (343, 169, 7, '2025-07-11', 3, 12000.00);
INSERT INTO public.service_usage VALUES (344, 169, 3, '2025-07-11', 2, 3500.00);
INSERT INTO public.service_usage VALUES (345, 169, 5, '2025-07-11', 1, 15000.00);
INSERT INTO public.service_usage VALUES (346, 170, 6, '2025-07-15', 3, 600.00);
INSERT INTO public.service_usage VALUES (347, 170, 7, '2025-07-14', 2, 12000.00);
INSERT INTO public.service_usage VALUES (348, 170, 5, '2025-07-14', 3, 15000.00);
INSERT INTO public.service_usage VALUES (349, 170, 3, '2025-07-15', 2, 3500.00);
INSERT INTO public.service_usage VALUES (350, 171, 2, '2025-07-19', 3, 6000.00);
INSERT INTO public.service_usage VALUES (351, 172, 4, '2025-07-25', 4, 1800.00);
INSERT INTO public.service_usage VALUES (352, 172, 4, '2025-07-24', 1, 1800.00);
INSERT INTO public.service_usage VALUES (353, 173, 6, '2025-07-26', 1, 600.00);
INSERT INTO public.service_usage VALUES (354, 173, 4, '2025-07-26', 3, 1800.00);
INSERT INTO public.service_usage VALUES (355, 174, 7, '2025-07-28', 3, 12000.00);
INSERT INTO public.service_usage VALUES (356, 174, 1, '2025-07-29', 2, 2500.00);
INSERT INTO public.service_usage VALUES (357, 174, 6, '2025-07-29', 3, 600.00);
INSERT INTO public.service_usage VALUES (358, 176, 3, '2025-08-06', 1, 3500.00);
INSERT INTO public.service_usage VALUES (359, 176, 1, '2025-08-06', 4, 2500.00);
INSERT INTO public.service_usage VALUES (360, 177, 3, '2025-08-09', 2, 3500.00);
INSERT INTO public.service_usage VALUES (361, 178, 4, '2025-08-16', 1, 1800.00);
INSERT INTO public.service_usage VALUES (362, 179, 7, '2025-08-22', 2, 12000.00);
INSERT INTO public.service_usage VALUES (363, 179, 6, '2025-08-21', 1, 600.00);
INSERT INTO public.service_usage VALUES (364, 179, 4, '2025-08-23', 3, 1800.00);
INSERT INTO public.service_usage VALUES (365, 180, 2, '2025-08-25', 1, 6000.00);
INSERT INTO public.service_usage VALUES (366, 180, 7, '2025-08-26', 2, 12000.00);
INSERT INTO public.service_usage VALUES (367, 180, 3, '2025-08-26', 1, 3500.00);
INSERT INTO public.service_usage VALUES (368, 181, 4, '2025-08-27', 1, 1800.00);
INSERT INTO public.service_usage VALUES (369, 181, 1, '2025-08-27', 3, 2500.00);
INSERT INTO public.service_usage VALUES (370, 181, 1, '2025-08-27', 1, 2500.00);
INSERT INTO public.service_usage VALUES (371, 182, 7, '2025-08-31', 3, 12000.00);
INSERT INTO public.service_usage VALUES (372, 182, 1, '2025-08-31', 2, 2500.00);
INSERT INTO public.service_usage VALUES (373, 182, 5, '2025-08-30', 2, 15000.00);
INSERT INTO public.service_usage VALUES (374, 183, 7, '2025-09-04', 2, 12000.00);
INSERT INTO public.service_usage VALUES (375, 184, 5, '2025-09-06', 1, 15000.00);
INSERT INTO public.service_usage VALUES (376, 185, 4, '2025-09-09', 2, 1800.00);
INSERT INTO public.service_usage VALUES (377, 185, 1, '2025-09-11', 1, 2500.00);
INSERT INTO public.service_usage VALUES (378, 185, 6, '2025-09-12', 1, 600.00);
INSERT INTO public.service_usage VALUES (379, 187, 2, '2025-09-18', 2, 6000.00);
INSERT INTO public.service_usage VALUES (380, 187, 3, '2025-09-17', 3, 3500.00);
INSERT INTO public.service_usage VALUES (381, 187, 3, '2025-09-18', 4, 3500.00);
INSERT INTO public.service_usage VALUES (382, 188, 4, '2025-09-24', 2, 1800.00);
INSERT INTO public.service_usage VALUES (383, 188, 1, '2025-09-23', 4, 2500.00);
INSERT INTO public.service_usage VALUES (384, 189, 4, '2025-09-28', 1, 1800.00);
INSERT INTO public.service_usage VALUES (385, 189, 7, '2025-09-27', 3, 12000.00);
INSERT INTO public.service_usage VALUES (386, 190, 2, '2025-07-03', 2, 6000.00);
INSERT INTO public.service_usage VALUES (387, 191, 6, '2025-07-08', 1, 600.00);
INSERT INTO public.service_usage VALUES (388, 192, 2, '2025-07-12', 2, 6000.00);
INSERT INTO public.service_usage VALUES (389, 192, 1, '2025-07-12', 1, 2500.00);
INSERT INTO public.service_usage VALUES (390, 192, 7, '2025-07-12', 3, 12000.00);
INSERT INTO public.service_usage VALUES (391, 193, 4, '2025-07-14', 4, 1800.00);
INSERT INTO public.service_usage VALUES (392, 193, 5, '2025-07-14', 3, 15000.00);
INSERT INTO public.service_usage VALUES (393, 194, 4, '2025-07-15', 1, 1800.00);
INSERT INTO public.service_usage VALUES (394, 196, 4, '2025-07-26', 3, 1800.00);
INSERT INTO public.service_usage VALUES (395, 197, 2, '2025-07-30', 1, 6000.00);
INSERT INTO public.service_usage VALUES (396, 198, 5, '2025-08-03', 3, 15000.00);
INSERT INTO public.service_usage VALUES (397, 198, 6, '2025-08-01', 3, 600.00);
INSERT INTO public.service_usage VALUES (398, 198, 3, '2025-08-03', 1, 3500.00);
INSERT INTO public.service_usage VALUES (399, 198, 6, '2025-08-02', 2, 600.00);
INSERT INTO public.service_usage VALUES (400, 199, 7, '2025-08-09', 3, 12000.00);
INSERT INTO public.service_usage VALUES (401, 199, 5, '2025-08-10', 3, 15000.00);
INSERT INTO public.service_usage VALUES (402, 199, 2, '2025-08-07', 4, 6000.00);
INSERT INTO public.service_usage VALUES (403, 200, 6, '2025-08-13', 1, 600.00);
INSERT INTO public.service_usage VALUES (404, 200, 2, '2025-08-16', 2, 6000.00);
INSERT INTO public.service_usage VALUES (405, 200, 3, '2025-08-12', 3, 3500.00);
INSERT INTO public.service_usage VALUES (406, 200, 1, '2025-08-13', 4, 2500.00);
INSERT INTO public.service_usage VALUES (407, 201, 2, '2025-08-19', 1, 6000.00);
INSERT INTO public.service_usage VALUES (408, 202, 7, '2025-08-25', 3, 12000.00);
INSERT INTO public.service_usage VALUES (409, 202, 1, '2025-08-22', 1, 2500.00);
INSERT INTO public.service_usage VALUES (410, 203, 7, '2025-08-28', 2, 12000.00);
INSERT INTO public.service_usage VALUES (411, 204, 2, '2025-09-03', 4, 6000.00);
INSERT INTO public.service_usage VALUES (412, 204, 3, '2025-09-02', 3, 3500.00);
INSERT INTO public.service_usage VALUES (413, 205, 7, '2025-09-08', 1, 12000.00);
INSERT INTO public.service_usage VALUES (414, 205, 1, '2025-09-04', 3, 2500.00);
INSERT INTO public.service_usage VALUES (415, 206, 6, '2025-09-09', 3, 600.00);
INSERT INTO public.service_usage VALUES (416, 206, 6, '2025-09-09', 2, 600.00);
INSERT INTO public.service_usage VALUES (417, 207, 1, '2025-09-10', 2, 2500.00);
INSERT INTO public.service_usage VALUES (418, 207, 5, '2025-09-12', 3, 15000.00);
INSERT INTO public.service_usage VALUES (419, 207, 1, '2025-09-10', 2, 2500.00);
INSERT INTO public.service_usage VALUES (420, 207, 2, '2025-09-12', 2, 6000.00);
INSERT INTO public.service_usage VALUES (421, 208, 1, '2025-09-17', 4, 2500.00);
INSERT INTO public.service_usage VALUES (422, 208, 1, '2025-09-17', 1, 2500.00);
INSERT INTO public.service_usage VALUES (423, 208, 5, '2025-09-17', 4, 15000.00);
INSERT INTO public.service_usage VALUES (424, 208, 3, '2025-09-17', 1, 3500.00);
INSERT INTO public.service_usage VALUES (425, 210, 1, '2025-09-27', 2, 2500.00);
INSERT INTO public.service_usage VALUES (426, 210, 2, '2025-09-27', 1, 6000.00);
INSERT INTO public.service_usage VALUES (427, 210, 5, '2025-09-28', 2, 15000.00);
INSERT INTO public.service_usage VALUES (428, 211, 2, '2025-07-04', 2, 6000.00);
INSERT INTO public.service_usage VALUES (429, 211, 1, '2025-07-03', 4, 2500.00);
INSERT INTO public.service_usage VALUES (430, 211, 2, '2025-07-03', 4, 6000.00);
INSERT INTO public.service_usage VALUES (431, 212, 7, '2025-07-07', 3, 12000.00);
INSERT INTO public.service_usage VALUES (432, 214, 1, '2025-07-16', 2, 2500.00);
INSERT INTO public.service_usage VALUES (433, 214, 1, '2025-07-16', 4, 2500.00);
INSERT INTO public.service_usage VALUES (434, 215, 1, '2025-07-19', 2, 2500.00);
INSERT INTO public.service_usage VALUES (435, 216, 2, '2025-07-24', 2, 6000.00);
INSERT INTO public.service_usage VALUES (436, 216, 6, '2025-07-23', 4, 600.00);
INSERT INTO public.service_usage VALUES (437, 217, 1, '2025-07-26', 4, 2500.00);
INSERT INTO public.service_usage VALUES (438, 217, 5, '2025-07-27', 3, 15000.00);
INSERT INTO public.service_usage VALUES (439, 218, 4, '2025-07-30', 3, 1800.00);
INSERT INTO public.service_usage VALUES (440, 218, 5, '2025-07-30', 3, 15000.00);
INSERT INTO public.service_usage VALUES (441, 218, 7, '2025-07-30', 2, 12000.00);
INSERT INTO public.service_usage VALUES (442, 218, 4, '2025-07-30', 2, 1800.00);
INSERT INTO public.service_usage VALUES (443, 219, 3, '2025-08-02', 3, 3500.00);
INSERT INTO public.service_usage VALUES (444, 221, 7, '2025-08-09', 3, 12000.00);
INSERT INTO public.service_usage VALUES (445, 221, 6, '2025-08-07', 3, 600.00);
INSERT INTO public.service_usage VALUES (446, 221, 1, '2025-08-09', 4, 2500.00);
INSERT INTO public.service_usage VALUES (447, 222, 2, '2025-08-12', 2, 6000.00);
INSERT INTO public.service_usage VALUES (448, 222, 6, '2025-08-12', 3, 600.00);
INSERT INTO public.service_usage VALUES (449, 222, 5, '2025-08-12', 2, 15000.00);
INSERT INTO public.service_usage VALUES (450, 222, 5, '2025-08-11', 4, 15000.00);
INSERT INTO public.service_usage VALUES (451, 223, 5, '2025-08-15', 3, 15000.00);
INSERT INTO public.service_usage VALUES (452, 223, 5, '2025-08-15', 2, 15000.00);
INSERT INTO public.service_usage VALUES (453, 223, 3, '2025-08-14', 2, 3500.00);
INSERT INTO public.service_usage VALUES (454, 226, 2, '2025-08-23', 2, 6000.00);
INSERT INTO public.service_usage VALUES (455, 226, 5, '2025-08-23', 2, 15000.00);
INSERT INTO public.service_usage VALUES (456, 226, 7, '2025-08-24', 4, 12000.00);
INSERT INTO public.service_usage VALUES (457, 227, 2, '2025-08-26', 4, 6000.00);
INSERT INTO public.service_usage VALUES (458, 227, 6, '2025-08-25', 3, 600.00);
INSERT INTO public.service_usage VALUES (459, 227, 2, '2025-08-26', 3, 6000.00);
INSERT INTO public.service_usage VALUES (460, 227, 5, '2025-08-25', 3, 15000.00);
INSERT INTO public.service_usage VALUES (461, 228, 5, '2025-08-28', 2, 15000.00);
INSERT INTO public.service_usage VALUES (462, 228, 5, '2025-08-28', 3, 15000.00);
INSERT INTO public.service_usage VALUES (463, 228, 4, '2025-08-29', 3, 1800.00);
INSERT INTO public.service_usage VALUES (464, 228, 1, '2025-08-28', 4, 2500.00);
INSERT INTO public.service_usage VALUES (465, 229, 4, '2025-09-01', 2, 1800.00);
INSERT INTO public.service_usage VALUES (466, 230, 7, '2025-09-04', 1, 12000.00);
INSERT INTO public.service_usage VALUES (467, 231, 3, '2025-09-06', 3, 3500.00);
INSERT INTO public.service_usage VALUES (468, 231, 3, '2025-09-10', 3, 3500.00);
INSERT INTO public.service_usage VALUES (469, 231, 3, '2025-09-08', 4, 3500.00);
INSERT INTO public.service_usage VALUES (470, 232, 4, '2025-09-11', 2, 1800.00);
INSERT INTO public.service_usage VALUES (471, 232, 6, '2025-09-11', 2, 600.00);
INSERT INTO public.service_usage VALUES (472, 233, 5, '2025-09-15', 2, 15000.00);
INSERT INTO public.service_usage VALUES (473, 233, 3, '2025-09-13', 4, 3500.00);
INSERT INTO public.service_usage VALUES (474, 235, 2, '2025-09-21', 4, 6000.00);
INSERT INTO public.service_usage VALUES (475, 236, 4, '2025-09-26', 3, 1800.00);
INSERT INTO public.service_usage VALUES (476, 237, 2, '2025-09-29', 3, 6000.00);
INSERT INTO public.service_usage VALUES (477, 239, 2, '2025-07-06', 2, 6000.00);
INSERT INTO public.service_usage VALUES (478, 239, 7, '2025-07-06', 1, 12000.00);
INSERT INTO public.service_usage VALUES (479, 241, 2, '2025-07-15', 3, 6000.00);
INSERT INTO public.service_usage VALUES (480, 244, 7, '2025-07-31', 4, 12000.00);
INSERT INTO public.service_usage VALUES (481, 244, 4, '2025-07-27', 3, 1800.00);
INSERT INTO public.service_usage VALUES (482, 244, 5, '2025-07-29', 4, 15000.00);
INSERT INTO public.service_usage VALUES (483, 245, 4, '2025-08-02', 1, 1800.00);
INSERT INTO public.service_usage VALUES (484, 245, 5, '2025-08-02', 4, 15000.00);
INSERT INTO public.service_usage VALUES (485, 246, 2, '2025-08-03', 4, 6000.00);
INSERT INTO public.service_usage VALUES (486, 246, 3, '2025-08-03', 2, 3500.00);
INSERT INTO public.service_usage VALUES (487, 246, 1, '2025-08-03', 3, 2500.00);
INSERT INTO public.service_usage VALUES (488, 247, 5, '2025-08-07', 3, 15000.00);
INSERT INTO public.service_usage VALUES (489, 247, 5, '2025-08-08', 2, 15000.00);
INSERT INTO public.service_usage VALUES (490, 248, 3, '2025-08-11', 2, 3500.00);
INSERT INTO public.service_usage VALUES (491, 248, 4, '2025-08-11', 3, 1800.00);
INSERT INTO public.service_usage VALUES (492, 249, 2, '2025-08-13', 1, 6000.00);
INSERT INTO public.service_usage VALUES (493, 249, 6, '2025-08-14', 3, 600.00);
INSERT INTO public.service_usage VALUES (494, 250, 7, '2025-08-16', 4, 12000.00);
INSERT INTO public.service_usage VALUES (495, 250, 4, '2025-08-16', 3, 1800.00);
INSERT INTO public.service_usage VALUES (496, 251, 7, '2025-08-20', 4, 12000.00);
INSERT INTO public.service_usage VALUES (497, 251, 6, '2025-08-19', 4, 600.00);
INSERT INTO public.service_usage VALUES (498, 251, 3, '2025-08-18', 3, 3500.00);
INSERT INTO public.service_usage VALUES (499, 252, 5, '2025-08-22', 3, 15000.00);
INSERT INTO public.service_usage VALUES (500, 253, 2, '2025-08-28', 4, 6000.00);
INSERT INTO public.service_usage VALUES (501, 253, 6, '2025-08-27', 3, 600.00);
INSERT INTO public.service_usage VALUES (502, 254, 1, '2025-08-30', 3, 2500.00);
INSERT INTO public.service_usage VALUES (503, 255, 2, '2025-09-06', 1, 6000.00);
INSERT INTO public.service_usage VALUES (504, 255, 2, '2025-09-06', 4, 6000.00);
INSERT INTO public.service_usage VALUES (505, 256, 5, '2025-09-11', 1, 15000.00);
INSERT INTO public.service_usage VALUES (506, 256, 2, '2025-09-08', 3, 6000.00);
INSERT INTO public.service_usage VALUES (507, 256, 1, '2025-09-09', 2, 2500.00);
INSERT INTO public.service_usage VALUES (508, 256, 6, '2025-09-09', 4, 600.00);
INSERT INTO public.service_usage VALUES (509, 257, 6, '2025-09-16', 3, 600.00);
INSERT INTO public.service_usage VALUES (510, 258, 3, '2025-09-20', 3, 3500.00);
INSERT INTO public.service_usage VALUES (511, 258, 2, '2025-09-20', 3, 6000.00);
INSERT INTO public.service_usage VALUES (512, 258, 5, '2025-09-19', 3, 15000.00);
INSERT INTO public.service_usage VALUES (513, 259, 4, '2025-09-24', 2, 1800.00);
INSERT INTO public.service_usage VALUES (514, 260, 2, '2025-09-26', 2, 6000.00);
INSERT INTO public.service_usage VALUES (515, 260, 3, '2025-09-27', 3, 3500.00);
INSERT INTO public.service_usage VALUES (516, 261, 7, '2025-10-01', 1, 12000.00);
INSERT INTO public.service_usage VALUES (517, 261, 1, '2025-09-30', 2, 2500.00);
INSERT INTO public.service_usage VALUES (518, 261, 7, '2025-10-02', 1, 12000.00);
INSERT INTO public.service_usage VALUES (519, 262, 3, '2025-07-02', 1, 3500.00);
INSERT INTO public.service_usage VALUES (520, 262, 5, '2025-07-01', 4, 15000.00);
INSERT INTO public.service_usage VALUES (521, 262, 1, '2025-07-01', 4, 2500.00);
INSERT INTO public.service_usage VALUES (522, 264, 4, '2025-07-10', 3, 1800.00);
INSERT INTO public.service_usage VALUES (523, 264, 5, '2025-07-10', 3, 15000.00);
INSERT INTO public.service_usage VALUES (524, 264, 2, '2025-07-10', 2, 6000.00);
INSERT INTO public.service_usage VALUES (525, 264, 5, '2025-07-11', 3, 15000.00);
INSERT INTO public.service_usage VALUES (526, 265, 7, '2025-07-13', 2, 12000.00);
INSERT INTO public.service_usage VALUES (527, 265, 3, '2025-07-12', 2, 3500.00);
INSERT INTO public.service_usage VALUES (528, 265, 2, '2025-07-12', 3, 6000.00);
INSERT INTO public.service_usage VALUES (529, 266, 3, '2025-07-16', 3, 3500.00);
INSERT INTO public.service_usage VALUES (530, 266, 2, '2025-07-16', 2, 6000.00);
INSERT INTO public.service_usage VALUES (531, 266, 6, '2025-07-15', 1, 600.00);
INSERT INTO public.service_usage VALUES (532, 267, 6, '2025-07-19', 1, 600.00);
INSERT INTO public.service_usage VALUES (533, 267, 6, '2025-07-20', 3, 600.00);
INSERT INTO public.service_usage VALUES (534, 267, 6, '2025-07-22', 2, 600.00);
INSERT INTO public.service_usage VALUES (535, 267, 1, '2025-07-19', 3, 2500.00);
INSERT INTO public.service_usage VALUES (536, 268, 5, '2025-07-26', 3, 15000.00);
INSERT INTO public.service_usage VALUES (537, 268, 4, '2025-07-26', 4, 1800.00);
INSERT INTO public.service_usage VALUES (538, 268, 5, '2025-07-24', 2, 15000.00);
INSERT INTO public.service_usage VALUES (539, 269, 2, '2025-07-29', 1, 6000.00);
INSERT INTO public.service_usage VALUES (540, 269, 4, '2025-07-30', 3, 1800.00);
INSERT INTO public.service_usage VALUES (541, 271, 1, '2025-08-07', 2, 2500.00);
INSERT INTO public.service_usage VALUES (542, 271, 1, '2025-08-06', 3, 2500.00);
INSERT INTO public.service_usage VALUES (543, 271, 5, '2025-08-06', 1, 15000.00);
INSERT INTO public.service_usage VALUES (544, 271, 1, '2025-08-06', 4, 2500.00);
INSERT INTO public.service_usage VALUES (545, 272, 4, '2025-08-11', 2, 1800.00);
INSERT INTO public.service_usage VALUES (546, 272, 4, '2025-08-11', 2, 1800.00);
INSERT INTO public.service_usage VALUES (547, 272, 6, '2025-08-11', 1, 600.00);
INSERT INTO public.service_usage VALUES (548, 273, 5, '2025-08-13', 1, 15000.00);
INSERT INTO public.service_usage VALUES (549, 273, 4, '2025-08-13', 2, 1800.00);
INSERT INTO public.service_usage VALUES (550, 275, 2, '2025-08-20', 2, 6000.00);
INSERT INTO public.service_usage VALUES (551, 275, 1, '2025-08-20', 2, 2500.00);
INSERT INTO public.service_usage VALUES (552, 275, 2, '2025-08-19', 4, 6000.00);
INSERT INTO public.service_usage VALUES (553, 276, 3, '2025-08-26', 4, 3500.00);
INSERT INTO public.service_usage VALUES (554, 277, 7, '2025-08-28', 1, 12000.00);
INSERT INTO public.service_usage VALUES (555, 277, 7, '2025-08-28', 2, 12000.00);
INSERT INTO public.service_usage VALUES (556, 277, 6, '2025-08-27', 2, 600.00);
INSERT INTO public.service_usage VALUES (557, 277, 4, '2025-08-27', 3, 1800.00);
INSERT INTO public.service_usage VALUES (558, 278, 3, '2025-08-29', 1, 3500.00);
INSERT INTO public.service_usage VALUES (559, 280, 2, '2025-09-07', 3, 6000.00);
INSERT INTO public.service_usage VALUES (560, 280, 3, '2025-09-06', 2, 3500.00);
INSERT INTO public.service_usage VALUES (561, 280, 4, '2025-09-06', 3, 1800.00);
INSERT INTO public.service_usage VALUES (562, 281, 5, '2025-09-12', 3, 15000.00);
INSERT INTO public.service_usage VALUES (563, 281, 2, '2025-09-11', 2, 6000.00);
INSERT INTO public.service_usage VALUES (564, 281, 1, '2025-09-12', 2, 2500.00);
INSERT INTO public.service_usage VALUES (565, 284, 3, '2025-09-27', 1, 3500.00);
INSERT INTO public.service_usage VALUES (566, 284, 5, '2025-09-27', 1, 15000.00);
INSERT INTO public.service_usage VALUES (567, 285, 3, '2025-09-30', 3, 3500.00);
INSERT INTO public.service_usage VALUES (568, 285, 1, '2025-10-01', 3, 2500.00);
INSERT INTO public.service_usage VALUES (569, 285, 5, '2025-09-30', 4, 15000.00);
INSERT INTO public.service_usage VALUES (570, 285, 1, '2025-10-02', 2, 2500.00);
INSERT INTO public.service_usage VALUES (571, 286, 5, '2025-07-01', 4, 15000.00);
INSERT INTO public.service_usage VALUES (572, 286, 4, '2025-07-01', 4, 1800.00);
INSERT INTO public.service_usage VALUES (573, 286, 2, '2025-07-01', 2, 6000.00);
INSERT INTO public.service_usage VALUES (574, 287, 1, '2025-07-05', 1, 2500.00);
INSERT INTO public.service_usage VALUES (575, 288, 2, '2025-07-10', 3, 6000.00);
INSERT INTO public.service_usage VALUES (576, 288, 7, '2025-07-09', 4, 12000.00);
INSERT INTO public.service_usage VALUES (577, 289, 2, '2025-07-13', 2, 6000.00);
INSERT INTO public.service_usage VALUES (578, 290, 6, '2025-07-17', 2, 600.00);
INSERT INTO public.service_usage VALUES (579, 290, 3, '2025-07-16', 2, 3500.00);
INSERT INTO public.service_usage VALUES (580, 292, 1, '2025-07-28', 3, 2500.00);
INSERT INTO public.service_usage VALUES (581, 292, 2, '2025-07-26', 2, 6000.00);
INSERT INTO public.service_usage VALUES (582, 292, 1, '2025-07-27', 2, 2500.00);
INSERT INTO public.service_usage VALUES (583, 293, 1, '2025-08-02', 2, 2500.00);
INSERT INTO public.service_usage VALUES (584, 293, 2, '2025-08-03', 2, 6000.00);
INSERT INTO public.service_usage VALUES (585, 293, 4, '2025-08-02', 1, 1800.00);
INSERT INTO public.service_usage VALUES (586, 293, 2, '2025-08-02', 2, 6000.00);
INSERT INTO public.service_usage VALUES (587, 295, 4, '2025-08-11', 2, 1800.00);
INSERT INTO public.service_usage VALUES (588, 295, 3, '2025-08-13', 2, 3500.00);
INSERT INTO public.service_usage VALUES (589, 295, 3, '2025-08-11', 1, 3500.00);
INSERT INTO public.service_usage VALUES (590, 296, 6, '2025-08-18', 3, 600.00);
INSERT INTO public.service_usage VALUES (591, 296, 3, '2025-08-18', 3, 3500.00);
INSERT INTO public.service_usage VALUES (592, 297, 4, '2025-08-19', 4, 1800.00);
INSERT INTO public.service_usage VALUES (593, 297, 6, '2025-08-20', 4, 600.00);
INSERT INTO public.service_usage VALUES (594, 297, 5, '2025-08-20', 3, 15000.00);
INSERT INTO public.service_usage VALUES (595, 297, 6, '2025-08-20', 2, 600.00);
INSERT INTO public.service_usage VALUES (596, 299, 1, '2025-08-28', 3, 2500.00);
INSERT INTO public.service_usage VALUES (597, 299, 2, '2025-08-28', 3, 6000.00);
INSERT INTO public.service_usage VALUES (598, 300, 7, '2025-08-30', 1, 12000.00);
INSERT INTO public.service_usage VALUES (599, 302, 6, '2025-09-09', 2, 600.00);
INSERT INTO public.service_usage VALUES (600, 302, 6, '2025-09-09', 3, 600.00);
INSERT INTO public.service_usage VALUES (601, 302, 6, '2025-09-07', 1, 600.00);
INSERT INTO public.service_usage VALUES (602, 303, 7, '2025-09-10', 2, 12000.00);
INSERT INTO public.service_usage VALUES (603, 303, 1, '2025-09-11', 1, 2500.00);
INSERT INTO public.service_usage VALUES (604, 304, 6, '2025-09-18', 2, 600.00);
INSERT INTO public.service_usage VALUES (605, 305, 1, '2025-09-24', 2, 2500.00);
INSERT INTO public.service_usage VALUES (606, 306, 6, '2025-09-27', 1, 600.00);
INSERT INTO public.service_usage VALUES (607, 307, 3, '2025-10-01', 4, 3500.00);
INSERT INTO public.service_usage VALUES (608, 308, 7, '2025-07-02', 2, 12000.00);
INSERT INTO public.service_usage VALUES (609, 309, 1, '2025-07-09', 1, 2500.00);
INSERT INTO public.service_usage VALUES (610, 309, 1, '2025-07-09', 1, 2500.00);
INSERT INTO public.service_usage VALUES (611, 309, 6, '2025-07-10', 3, 600.00);
INSERT INTO public.service_usage VALUES (612, 310, 7, '2025-07-12', 1, 12000.00);
INSERT INTO public.service_usage VALUES (613, 310, 2, '2025-07-11', 1, 6000.00);
INSERT INTO public.service_usage VALUES (614, 311, 2, '2025-07-18', 3, 6000.00);
INSERT INTO public.service_usage VALUES (615, 311, 1, '2025-07-16', 3, 2500.00);
INSERT INTO public.service_usage VALUES (616, 311, 2, '2025-07-18', 1, 6000.00);
INSERT INTO public.service_usage VALUES (617, 312, 3, '2025-07-23', 2, 3500.00);
INSERT INTO public.service_usage VALUES (618, 312, 7, '2025-07-23', 4, 12000.00);
INSERT INTO public.service_usage VALUES (619, 312, 5, '2025-07-22', 1, 15000.00);
INSERT INTO public.service_usage VALUES (620, 312, 3, '2025-07-22', 3, 3500.00);
INSERT INTO public.service_usage VALUES (621, 313, 5, '2025-07-27', 3, 15000.00);
INSERT INTO public.service_usage VALUES (622, 313, 5, '2025-07-27', 2, 15000.00);
INSERT INTO public.service_usage VALUES (623, 313, 7, '2025-07-27', 2, 12000.00);
INSERT INTO public.service_usage VALUES (624, 314, 2, '2025-08-01', 4, 6000.00);
INSERT INTO public.service_usage VALUES (625, 315, 2, '2025-08-06', 3, 6000.00);
INSERT INTO public.service_usage VALUES (626, 316, 7, '2025-08-11', 2, 12000.00);
INSERT INTO public.service_usage VALUES (627, 316, 5, '2025-08-12', 1, 15000.00);
INSERT INTO public.service_usage VALUES (628, 316, 6, '2025-08-11', 1, 600.00);
INSERT INTO public.service_usage VALUES (629, 316, 7, '2025-08-11', 2, 12000.00);
INSERT INTO public.service_usage VALUES (630, 317, 5, '2025-08-15', 1, 15000.00);
INSERT INTO public.service_usage VALUES (631, 317, 5, '2025-08-14', 1, 15000.00);
INSERT INTO public.service_usage VALUES (632, 317, 4, '2025-08-15', 2, 1800.00);
INSERT INTO public.service_usage VALUES (633, 317, 4, '2025-08-13', 3, 1800.00);
INSERT INTO public.service_usage VALUES (634, 318, 4, '2025-08-20', 4, 1800.00);
INSERT INTO public.service_usage VALUES (635, 318, 1, '2025-08-20', 3, 2500.00);
INSERT INTO public.service_usage VALUES (636, 318, 3, '2025-08-20', 3, 3500.00);
INSERT INTO public.service_usage VALUES (637, 318, 1, '2025-08-19', 3, 2500.00);
INSERT INTO public.service_usage VALUES (638, 319, 1, '2025-08-25', 1, 2500.00);
INSERT INTO public.service_usage VALUES (639, 320, 7, '2025-08-29', 3, 12000.00);
INSERT INTO public.service_usage VALUES (640, 320, 6, '2025-08-28', 3, 600.00);
INSERT INTO public.service_usage VALUES (641, 320, 5, '2025-08-27', 1, 15000.00);
INSERT INTO public.service_usage VALUES (642, 320, 4, '2025-08-28', 2, 1800.00);
INSERT INTO public.service_usage VALUES (643, 321, 2, '2025-09-02', 3, 6000.00);
INSERT INTO public.service_usage VALUES (644, 322, 7, '2025-09-07', 3, 12000.00);
INSERT INTO public.service_usage VALUES (645, 322, 5, '2025-09-08', 2, 15000.00);
INSERT INTO public.service_usage VALUES (646, 322, 3, '2025-09-07', 4, 3500.00);
INSERT INTO public.service_usage VALUES (647, 323, 6, '2025-09-13', 1, 600.00);
INSERT INTO public.service_usage VALUES (648, 323, 7, '2025-09-13', 1, 12000.00);
INSERT INTO public.service_usage VALUES (649, 323, 2, '2025-09-13', 4, 6000.00);
INSERT INTO public.service_usage VALUES (650, 324, 4, '2025-09-18', 2, 1800.00);
INSERT INTO public.service_usage VALUES (651, 325, 3, '2025-09-20', 4, 3500.00);
INSERT INTO public.service_usage VALUES (652, 325, 4, '2025-09-23', 3, 1800.00);
INSERT INTO public.service_usage VALUES (653, 325, 6, '2025-09-20', 4, 600.00);
INSERT INTO public.service_usage VALUES (654, 325, 5, '2025-09-23', 3, 15000.00);
INSERT INTO public.service_usage VALUES (655, 326, 5, '2025-09-27', 3, 15000.00);
INSERT INTO public.service_usage VALUES (656, 327, 7, '2025-10-01', 2, 12000.00);
INSERT INTO public.service_usage VALUES (657, 327, 3, '2025-09-30', 3, 3500.00);
INSERT INTO public.service_usage VALUES (658, 328, 3, '2025-07-02', 3, 3500.00);
INSERT INTO public.service_usage VALUES (659, 328, 2, '2025-07-01', 2, 6000.00);
INSERT INTO public.service_usage VALUES (660, 328, 4, '2025-07-01', 3, 1800.00);
INSERT INTO public.service_usage VALUES (661, 328, 4, '2025-07-02', 2, 1800.00);
INSERT INTO public.service_usage VALUES (662, 329, 1, '2025-07-06', 4, 2500.00);
INSERT INTO public.service_usage VALUES (663, 330, 6, '2025-07-11', 1, 600.00);
INSERT INTO public.service_usage VALUES (664, 330, 6, '2025-07-09', 3, 600.00);
INSERT INTO public.service_usage VALUES (665, 330, 4, '2025-07-09', 2, 1800.00);
INSERT INTO public.service_usage VALUES (666, 330, 7, '2025-07-10', 4, 12000.00);
INSERT INTO public.service_usage VALUES (667, 331, 6, '2025-07-16', 2, 600.00);
INSERT INTO public.service_usage VALUES (668, 332, 3, '2025-07-20', 3, 3500.00);
INSERT INTO public.service_usage VALUES (669, 332, 6, '2025-07-20', 4, 600.00);
INSERT INTO public.service_usage VALUES (670, 332, 7, '2025-07-20', 1, 12000.00);
INSERT INTO public.service_usage VALUES (671, 332, 1, '2025-07-21', 2, 2500.00);
INSERT INTO public.service_usage VALUES (672, 333, 4, '2025-07-24', 2, 1800.00);
INSERT INTO public.service_usage VALUES (673, 333, 1, '2025-07-25', 2, 2500.00);
INSERT INTO public.service_usage VALUES (674, 333, 5, '2025-07-24', 1, 15000.00);
INSERT INTO public.service_usage VALUES (675, 334, 4, '2025-07-27', 4, 1800.00);
INSERT INTO public.service_usage VALUES (676, 334, 4, '2025-07-27', 3, 1800.00);
INSERT INTO public.service_usage VALUES (677, 334, 2, '2025-07-27', 3, 6000.00);
INSERT INTO public.service_usage VALUES (678, 334, 4, '2025-07-27', 2, 1800.00);
INSERT INTO public.service_usage VALUES (679, 335, 7, '2025-07-30', 1, 12000.00);
INSERT INTO public.service_usage VALUES (680, 335, 5, '2025-07-30', 1, 15000.00);
INSERT INTO public.service_usage VALUES (681, 335, 6, '2025-07-30', 2, 600.00);
INSERT INTO public.service_usage VALUES (682, 336, 6, '2025-08-02', 3, 600.00);
INSERT INTO public.service_usage VALUES (683, 336, 3, '2025-08-03', 3, 3500.00);
INSERT INTO public.service_usage VALUES (684, 337, 7, '2025-08-07', 3, 12000.00);
INSERT INTO public.service_usage VALUES (685, 337, 4, '2025-08-07', 3, 1800.00);
INSERT INTO public.service_usage VALUES (686, 337, 4, '2025-08-07', 1, 1800.00);
INSERT INTO public.service_usage VALUES (687, 337, 5, '2025-08-07', 4, 15000.00);
INSERT INTO public.service_usage VALUES (688, 338, 2, '2025-08-08', 4, 6000.00);
INSERT INTO public.service_usage VALUES (689, 338, 5, '2025-08-09', 3, 15000.00);
INSERT INTO public.service_usage VALUES (690, 338, 5, '2025-08-09', 3, 15000.00);
INSERT INTO public.service_usage VALUES (691, 338, 7, '2025-08-09', 1, 12000.00);
INSERT INTO public.service_usage VALUES (692, 339, 3, '2025-08-10', 3, 3500.00);
INSERT INTO public.service_usage VALUES (693, 339, 7, '2025-08-10', 2, 12000.00);
INSERT INTO public.service_usage VALUES (694, 340, 2, '2025-08-14', 4, 6000.00);
INSERT INTO public.service_usage VALUES (695, 340, 2, '2025-08-14', 2, 6000.00);
INSERT INTO public.service_usage VALUES (696, 340, 2, '2025-08-14', 1, 6000.00);
INSERT INTO public.service_usage VALUES (697, 341, 2, '2025-08-18', 1, 6000.00);
INSERT INTO public.service_usage VALUES (698, 341, 1, '2025-08-18', 4, 2500.00);
INSERT INTO public.service_usage VALUES (699, 341, 4, '2025-08-17', 3, 1800.00);
INSERT INTO public.service_usage VALUES (700, 341, 7, '2025-08-18', 1, 12000.00);
INSERT INTO public.service_usage VALUES (701, 342, 4, '2025-08-22', 2, 1800.00);
INSERT INTO public.service_usage VALUES (702, 342, 7, '2025-08-22', 2, 12000.00);
INSERT INTO public.service_usage VALUES (703, 342, 6, '2025-08-22', 3, 600.00);
INSERT INTO public.service_usage VALUES (704, 342, 7, '2025-08-22', 1, 12000.00);
INSERT INTO public.service_usage VALUES (705, 343, 1, '2025-08-24', 3, 2500.00);
INSERT INTO public.service_usage VALUES (706, 343, 2, '2025-08-25', 3, 6000.00);
INSERT INTO public.service_usage VALUES (707, 343, 2, '2025-08-25', 2, 6000.00);
INSERT INTO public.service_usage VALUES (708, 344, 5, '2025-08-28', 3, 15000.00);
INSERT INTO public.service_usage VALUES (709, 344, 3, '2025-08-29', 1, 3500.00);
INSERT INTO public.service_usage VALUES (710, 345, 5, '2025-09-03', 4, 15000.00);
INSERT INTO public.service_usage VALUES (711, 345, 5, '2025-09-03', 1, 15000.00);
INSERT INTO public.service_usage VALUES (712, 345, 6, '2025-09-04', 3, 600.00);
INSERT INTO public.service_usage VALUES (713, 346, 6, '2025-09-07', 2, 600.00);
INSERT INTO public.service_usage VALUES (714, 346, 7, '2025-09-08', 1, 12000.00);
INSERT INTO public.service_usage VALUES (715, 346, 2, '2025-09-07', 1, 6000.00);
INSERT INTO public.service_usage VALUES (716, 347, 6, '2025-09-12', 3, 600.00);
INSERT INTO public.service_usage VALUES (717, 347, 4, '2025-09-11', 2, 1800.00);
INSERT INTO public.service_usage VALUES (718, 347, 2, '2025-09-13', 3, 6000.00);
INSERT INTO public.service_usage VALUES (719, 347, 5, '2025-09-14', 1, 15000.00);
INSERT INTO public.service_usage VALUES (720, 348, 1, '2025-09-16', 3, 2500.00);
INSERT INTO public.service_usage VALUES (721, 349, 4, '2025-09-18', 4, 1800.00);
INSERT INTO public.service_usage VALUES (722, 350, 2, '2025-09-23', 3, 6000.00);
INSERT INTO public.service_usage VALUES (723, 350, 1, '2025-09-23', 1, 2500.00);
INSERT INTO public.service_usage VALUES (724, 351, 7, '2025-09-25', 2, 12000.00);
INSERT INTO public.service_usage VALUES (725, 351, 1, '2025-09-24', 1, 2500.00);
INSERT INTO public.service_usage VALUES (726, 351, 6, '2025-09-25', 2, 600.00);
INSERT INTO public.service_usage VALUES (727, 352, 7, '2025-09-27', 1, 12000.00);
INSERT INTO public.service_usage VALUES (728, 352, 1, '2025-09-27', 4, 2500.00);
INSERT INTO public.service_usage VALUES (729, 352, 3, '2025-09-28', 4, 3500.00);
INSERT INTO public.service_usage VALUES (730, 352, 6, '2025-09-27', 4, 600.00);
INSERT INTO public.service_usage VALUES (731, 353, 2, '2025-09-30', 2, 6000.00);
INSERT INTO public.service_usage VALUES (732, 354, 5, '2025-07-02', 2, 15000.00);
INSERT INTO public.service_usage VALUES (733, 354, 3, '2025-07-02', 2, 3500.00);
INSERT INTO public.service_usage VALUES (734, 355, 2, '2025-07-06', 3, 6000.00);
INSERT INTO public.service_usage VALUES (735, 355, 7, '2025-07-05', 3, 12000.00);
INSERT INTO public.service_usage VALUES (736, 355, 4, '2025-07-06', 1, 1800.00);
INSERT INTO public.service_usage VALUES (737, 355, 3, '2025-07-06', 1, 3500.00);
INSERT INTO public.service_usage VALUES (738, 356, 6, '2025-07-11', 3, 600.00);
INSERT INTO public.service_usage VALUES (739, 356, 3, '2025-07-09', 2, 3500.00);
INSERT INTO public.service_usage VALUES (740, 356, 6, '2025-07-08', 2, 600.00);
INSERT INTO public.service_usage VALUES (741, 356, 4, '2025-07-10', 4, 1800.00);
INSERT INTO public.service_usage VALUES (742, 357, 6, '2025-07-12', 4, 600.00);
INSERT INTO public.service_usage VALUES (743, 357, 6, '2025-07-12', 3, 600.00);
INSERT INTO public.service_usage VALUES (744, 357, 4, '2025-07-12', 3, 1800.00);
INSERT INTO public.service_usage VALUES (745, 357, 4, '2025-07-13', 1, 1800.00);
INSERT INTO public.service_usage VALUES (746, 358, 7, '2025-07-16', 2, 12000.00);
INSERT INTO public.service_usage VALUES (747, 359, 1, '2025-07-21', 1, 2500.00);
INSERT INTO public.service_usage VALUES (748, 360, 1, '2025-07-26', 2, 2500.00);
INSERT INTO public.service_usage VALUES (749, 360, 3, '2025-07-24', 4, 3500.00);
INSERT INTO public.service_usage VALUES (750, 360, 7, '2025-07-23', 4, 12000.00);
INSERT INTO public.service_usage VALUES (751, 361, 2, '2025-07-30', 3, 6000.00);
INSERT INTO public.service_usage VALUES (752, 361, 3, '2025-07-30', 1, 3500.00);
INSERT INTO public.service_usage VALUES (753, 361, 1, '2025-07-29', 3, 2500.00);
INSERT INTO public.service_usage VALUES (754, 363, 4, '2025-08-04', 3, 1800.00);
INSERT INTO public.service_usage VALUES (755, 364, 1, '2025-08-08', 2, 2500.00);
INSERT INTO public.service_usage VALUES (756, 365, 6, '2025-08-13', 2, 600.00);
INSERT INTO public.service_usage VALUES (757, 365, 1, '2025-08-13', 1, 2500.00);
INSERT INTO public.service_usage VALUES (758, 365, 5, '2025-08-12', 3, 15000.00);
INSERT INTO public.service_usage VALUES (759, 365, 6, '2025-08-13', 2, 600.00);
INSERT INTO public.service_usage VALUES (760, 366, 6, '2025-08-15', 4, 600.00);
INSERT INTO public.service_usage VALUES (761, 366, 6, '2025-08-15', 2, 600.00);
INSERT INTO public.service_usage VALUES (762, 367, 3, '2025-08-17', 3, 3500.00);
INSERT INTO public.service_usage VALUES (763, 368, 7, '2025-08-25', 4, 12000.00);
INSERT INTO public.service_usage VALUES (764, 369, 1, '2025-08-27', 1, 2500.00);
INSERT INTO public.service_usage VALUES (765, 369, 2, '2025-08-28', 3, 6000.00);
INSERT INTO public.service_usage VALUES (766, 371, 5, '2025-09-05', 1, 15000.00);
INSERT INTO public.service_usage VALUES (767, 371, 7, '2025-09-06', 4, 12000.00);
INSERT INTO public.service_usage VALUES (768, 373, 3, '2025-09-13', 3, 3500.00);
INSERT INTO public.service_usage VALUES (769, 373, 2, '2025-09-12', 4, 6000.00);
INSERT INTO public.service_usage VALUES (770, 374, 3, '2025-09-15', 2, 3500.00);
INSERT INTO public.service_usage VALUES (771, 375, 1, '2025-09-20', 3, 2500.00);
INSERT INTO public.service_usage VALUES (772, 376, 1, '2025-09-23', 4, 2500.00);
INSERT INTO public.service_usage VALUES (773, 377, 6, '2025-09-26', 2, 600.00);
INSERT INTO public.service_usage VALUES (774, 378, 2, '2025-09-30', 2, 6000.00);
INSERT INTO public.service_usage VALUES (775, 378, 4, '2025-09-30', 2, 1800.00);
INSERT INTO public.service_usage VALUES (776, 379, 4, '2025-07-01', 3, 1800.00);
INSERT INTO public.service_usage VALUES (777, 381, 4, '2025-07-06', 2, 1800.00);
INSERT INTO public.service_usage VALUES (778, 381, 4, '2025-07-07', 3, 1800.00);
INSERT INTO public.service_usage VALUES (779, 381, 4, '2025-07-06', 2, 1800.00);
INSERT INTO public.service_usage VALUES (780, 382, 2, '2025-07-12', 2, 6000.00);
INSERT INTO public.service_usage VALUES (781, 383, 1, '2025-07-16', 2, 2500.00);
INSERT INTO public.service_usage VALUES (782, 384, 4, '2025-07-20', 3, 1800.00);
INSERT INTO public.service_usage VALUES (783, 384, 4, '2025-07-19', 2, 1800.00);
INSERT INTO public.service_usage VALUES (784, 385, 1, '2025-07-24', 2, 2500.00);
INSERT INTO public.service_usage VALUES (785, 385, 2, '2025-07-24', 3, 6000.00);
INSERT INTO public.service_usage VALUES (786, 386, 2, '2025-07-28', 1, 6000.00);
INSERT INTO public.service_usage VALUES (787, 386, 2, '2025-07-29', 3, 6000.00);
INSERT INTO public.service_usage VALUES (788, 386, 7, '2025-07-27', 2, 12000.00);
INSERT INTO public.service_usage VALUES (789, 388, 4, '2025-08-10', 4, 1800.00);
INSERT INTO public.service_usage VALUES (790, 388, 4, '2025-08-08', 2, 1800.00);
INSERT INTO public.service_usage VALUES (791, 389, 5, '2025-08-11', 2, 15000.00);
INSERT INTO public.service_usage VALUES (792, 389, 5, '2025-08-11', 2, 15000.00);
INSERT INTO public.service_usage VALUES (793, 390, 1, '2025-08-16', 3, 2500.00);
INSERT INTO public.service_usage VALUES (794, 390, 5, '2025-08-16', 1, 15000.00);
INSERT INTO public.service_usage VALUES (795, 390, 5, '2025-08-16', 1, 15000.00);
INSERT INTO public.service_usage VALUES (796, 391, 1, '2025-08-20', 2, 2500.00);
INSERT INTO public.service_usage VALUES (797, 391, 5, '2025-08-20', 3, 15000.00);
INSERT INTO public.service_usage VALUES (798, 391, 5, '2025-08-21', 2, 15000.00);
INSERT INTO public.service_usage VALUES (799, 392, 7, '2025-08-25', 2, 12000.00);
INSERT INTO public.service_usage VALUES (800, 393, 2, '2025-08-31', 2, 6000.00);
INSERT INTO public.service_usage VALUES (801, 393, 1, '2025-09-01', 2, 2500.00);
INSERT INTO public.service_usage VALUES (802, 393, 1, '2025-09-01', 3, 2500.00);
INSERT INTO public.service_usage VALUES (803, 393, 2, '2025-09-01', 2, 6000.00);
INSERT INTO public.service_usage VALUES (804, 394, 1, '2025-09-05', 3, 2500.00);
INSERT INTO public.service_usage VALUES (805, 394, 7, '2025-09-06', 4, 12000.00);
INSERT INTO public.service_usage VALUES (806, 394, 1, '2025-09-06', 4, 2500.00);
INSERT INTO public.service_usage VALUES (807, 395, 3, '2025-09-11', 3, 3500.00);
INSERT INTO public.service_usage VALUES (808, 395, 3, '2025-09-10', 4, 3500.00);
INSERT INTO public.service_usage VALUES (809, 395, 7, '2025-09-11', 2, 12000.00);
INSERT INTO public.service_usage VALUES (810, 395, 7, '2025-09-11', 2, 12000.00);
INSERT INTO public.service_usage VALUES (811, 397, 5, '2025-09-16', 2, 15000.00);
INSERT INTO public.service_usage VALUES (812, 398, 1, '2025-09-20', 3, 2500.00);
INSERT INTO public.service_usage VALUES (813, 398, 6, '2025-09-19', 3, 600.00);
INSERT INTO public.service_usage VALUES (814, 398, 3, '2025-09-20', 3, 3500.00);
INSERT INTO public.service_usage VALUES (815, 399, 3, '2025-09-23', 3, 3500.00);
INSERT INTO public.service_usage VALUES (816, 399, 2, '2025-09-22', 2, 6000.00);
INSERT INTO public.service_usage VALUES (817, 399, 3, '2025-09-26', 4, 3500.00);
INSERT INTO public.service_usage VALUES (818, 401, 5, '2025-07-02', 2, 15000.00);
INSERT INTO public.service_usage VALUES (819, 401, 4, '2025-07-01', 3, 1800.00);
INSERT INTO public.service_usage VALUES (820, 401, 1, '2025-07-02', 2, 2500.00);
INSERT INTO public.service_usage VALUES (821, 402, 6, '2025-07-05', 2, 600.00);
INSERT INTO public.service_usage VALUES (822, 402, 1, '2025-07-05', 1, 2500.00);
INSERT INTO public.service_usage VALUES (823, 402, 7, '2025-07-06', 3, 12000.00);
INSERT INTO public.service_usage VALUES (824, 402, 7, '2025-07-06', 2, 12000.00);
INSERT INTO public.service_usage VALUES (825, 403, 3, '2025-07-09', 1, 3500.00);
INSERT INTO public.service_usage VALUES (826, 403, 1, '2025-07-09', 1, 2500.00);
INSERT INTO public.service_usage VALUES (827, 404, 1, '2025-07-11', 2, 2500.00);
INSERT INTO public.service_usage VALUES (828, 405, 2, '2025-07-16', 4, 6000.00);
INSERT INTO public.service_usage VALUES (829, 405, 1, '2025-07-15', 4, 2500.00);
INSERT INTO public.service_usage VALUES (830, 405, 7, '2025-07-16', 1, 12000.00);
INSERT INTO public.service_usage VALUES (831, 406, 2, '2025-07-21', 1, 6000.00);
INSERT INTO public.service_usage VALUES (832, 406, 5, '2025-07-21', 4, 15000.00);
INSERT INTO public.service_usage VALUES (833, 408, 2, '2025-07-31', 1, 6000.00);
INSERT INTO public.service_usage VALUES (834, 408, 4, '2025-07-31', 3, 1800.00);
INSERT INTO public.service_usage VALUES (835, 408, 7, '2025-07-30', 4, 12000.00);
INSERT INTO public.service_usage VALUES (836, 408, 4, '2025-07-31', 3, 1800.00);
INSERT INTO public.service_usage VALUES (837, 409, 3, '2025-08-04', 3, 3500.00);
INSERT INTO public.service_usage VALUES (838, 409, 1, '2025-08-04', 2, 2500.00);
INSERT INTO public.service_usage VALUES (839, 410, 4, '2025-08-07', 1, 1800.00);
INSERT INTO public.service_usage VALUES (840, 410, 2, '2025-08-07', 4, 6000.00);
INSERT INTO public.service_usage VALUES (841, 410, 7, '2025-08-07', 2, 12000.00);
INSERT INTO public.service_usage VALUES (842, 411, 3, '2025-08-14', 1, 3500.00);
INSERT INTO public.service_usage VALUES (843, 411, 4, '2025-08-13', 2, 1800.00);
INSERT INTO public.service_usage VALUES (844, 412, 6, '2025-08-18', 2, 600.00);
INSERT INTO public.service_usage VALUES (845, 412, 2, '2025-08-17', 2, 6000.00);
INSERT INTO public.service_usage VALUES (846, 412, 6, '2025-08-16', 1, 600.00);
INSERT INTO public.service_usage VALUES (847, 412, 7, '2025-08-18', 3, 12000.00);
INSERT INTO public.service_usage VALUES (848, 413, 6, '2025-08-21', 1, 600.00);
INSERT INTO public.service_usage VALUES (849, 414, 7, '2025-08-24', 1, 12000.00);
INSERT INTO public.service_usage VALUES (850, 415, 7, '2025-08-31', 1, 12000.00);
INSERT INTO public.service_usage VALUES (851, 415, 6, '2025-08-30', 4, 600.00);
INSERT INTO public.service_usage VALUES (852, 416, 6, '2025-09-05', 2, 600.00);
INSERT INTO public.service_usage VALUES (853, 416, 3, '2025-09-05', 2, 3500.00);
INSERT INTO public.service_usage VALUES (854, 417, 1, '2025-09-08', 4, 2500.00);
INSERT INTO public.service_usage VALUES (855, 417, 7, '2025-09-07', 4, 12000.00);
INSERT INTO public.service_usage VALUES (856, 418, 7, '2025-09-10', 3, 12000.00);
INSERT INTO public.service_usage VALUES (857, 419, 4, '2025-09-15', 2, 1800.00);
INSERT INTO public.service_usage VALUES (858, 419, 7, '2025-09-15', 1, 12000.00);
INSERT INTO public.service_usage VALUES (859, 420, 3, '2025-09-19', 3, 3500.00);
INSERT INTO public.service_usage VALUES (860, 421, 6, '2025-09-23', 3, 600.00);
INSERT INTO public.service_usage VALUES (861, 421, 1, '2025-09-24', 3, 2500.00);
INSERT INTO public.service_usage VALUES (862, 421, 1, '2025-09-22', 2, 2500.00);
INSERT INTO public.service_usage VALUES (863, 421, 1, '2025-09-21', 3, 2500.00);
INSERT INTO public.service_usage VALUES (864, 422, 4, '2025-09-28', 2, 1800.00);
INSERT INTO public.service_usage VALUES (865, 422, 2, '2025-09-27', 2, 6000.00);
INSERT INTO public.service_usage VALUES (866, 424, 4, '2025-07-02', 2, 1800.00);
INSERT INTO public.service_usage VALUES (867, 424, 5, '2025-07-02', 3, 15000.00);
INSERT INTO public.service_usage VALUES (868, 424, 2, '2025-07-02', 3, 6000.00);
INSERT INTO public.service_usage VALUES (869, 425, 4, '2025-07-03', 3, 1800.00);
INSERT INTO public.service_usage VALUES (870, 425, 4, '2025-07-03', 3, 1800.00);
INSERT INTO public.service_usage VALUES (871, 426, 4, '2025-07-08', 3, 1800.00);
INSERT INTO public.service_usage VALUES (872, 426, 3, '2025-07-07', 1, 3500.00);
INSERT INTO public.service_usage VALUES (873, 429, 7, '2025-07-21', 2, 12000.00);
INSERT INTO public.service_usage VALUES (874, 429, 4, '2025-07-21', 3, 1800.00);
INSERT INTO public.service_usage VALUES (875, 429, 2, '2025-07-21', 3, 6000.00);
INSERT INTO public.service_usage VALUES (876, 430, 5, '2025-07-25', 2, 15000.00);
INSERT INTO public.service_usage VALUES (877, 431, 3, '2025-07-27', 2, 3500.00);
INSERT INTO public.service_usage VALUES (878, 432, 7, '2025-07-31', 4, 12000.00);
INSERT INTO public.service_usage VALUES (879, 433, 2, '2025-08-01', 3, 6000.00);
INSERT INTO public.service_usage VALUES (880, 434, 7, '2025-08-08', 1, 12000.00);
INSERT INTO public.service_usage VALUES (881, 434, 3, '2025-08-08', 2, 3500.00);
INSERT INTO public.service_usage VALUES (882, 434, 7, '2025-08-07', 3, 12000.00);
INSERT INTO public.service_usage VALUES (883, 435, 1, '2025-08-09', 3, 2500.00);
INSERT INTO public.service_usage VALUES (884, 435, 5, '2025-08-09', 2, 15000.00);
INSERT INTO public.service_usage VALUES (885, 435, 2, '2025-08-10', 4, 6000.00);
INSERT INTO public.service_usage VALUES (886, 435, 7, '2025-08-11', 3, 12000.00);
INSERT INTO public.service_usage VALUES (887, 436, 1, '2025-08-12', 4, 2500.00);
INSERT INTO public.service_usage VALUES (888, 438, 3, '2025-08-19', 3, 3500.00);
INSERT INTO public.service_usage VALUES (889, 438, 2, '2025-08-19', 2, 6000.00);
INSERT INTO public.service_usage VALUES (890, 438, 1, '2025-08-19', 4, 2500.00);
INSERT INTO public.service_usage VALUES (891, 438, 3, '2025-08-19', 3, 3500.00);
INSERT INTO public.service_usage VALUES (892, 439, 5, '2025-08-21', 2, 15000.00);
INSERT INTO public.service_usage VALUES (893, 439, 2, '2025-08-21', 3, 6000.00);
INSERT INTO public.service_usage VALUES (894, 440, 2, '2025-08-25', 4, 6000.00);
INSERT INTO public.service_usage VALUES (895, 441, 4, '2025-08-27', 1, 1800.00);
INSERT INTO public.service_usage VALUES (896, 441, 3, '2025-08-28', 4, 3500.00);
INSERT INTO public.service_usage VALUES (897, 441, 1, '2025-08-28', 3, 2500.00);
INSERT INTO public.service_usage VALUES (898, 445, 2, '2025-09-12', 3, 6000.00);
INSERT INTO public.service_usage VALUES (899, 445, 6, '2025-09-12', 3, 600.00);
INSERT INTO public.service_usage VALUES (900, 445, 5, '2025-09-14', 4, 15000.00);
INSERT INTO public.service_usage VALUES (901, 446, 7, '2025-09-19', 3, 12000.00);
INSERT INTO public.service_usage VALUES (902, 447, 1, '2025-09-21', 1, 2500.00);
INSERT INTO public.service_usage VALUES (903, 447, 3, '2025-09-21', 3, 3500.00);
INSERT INTO public.service_usage VALUES (904, 448, 7, '2025-09-24', 2, 12000.00);
INSERT INTO public.service_usage VALUES (905, 450, 4, '2025-07-01', 2, 1800.00);
INSERT INTO public.service_usage VALUES (906, 450, 4, '2025-07-01', 2, 1800.00);
INSERT INTO public.service_usage VALUES (907, 450, 5, '2025-07-01', 3, 15000.00);
INSERT INTO public.service_usage VALUES (908, 451, 1, '2025-07-04', 4, 2500.00);
INSERT INTO public.service_usage VALUES (909, 451, 1, '2025-07-06', 1, 2500.00);
INSERT INTO public.service_usage VALUES (910, 452, 4, '2025-07-08', 2, 1800.00);
INSERT INTO public.service_usage VALUES (911, 452, 6, '2025-07-07', 3, 600.00);
INSERT INTO public.service_usage VALUES (912, 452, 1, '2025-07-09', 1, 2500.00);
INSERT INTO public.service_usage VALUES (913, 452, 6, '2025-07-10', 3, 600.00);
INSERT INTO public.service_usage VALUES (914, 453, 4, '2025-07-13', 3, 1800.00);
INSERT INTO public.service_usage VALUES (915, 453, 6, '2025-07-12', 3, 600.00);
INSERT INTO public.service_usage VALUES (916, 453, 4, '2025-07-12', 4, 1800.00);
INSERT INTO public.service_usage VALUES (917, 454, 5, '2025-07-15', 2, 15000.00);
INSERT INTO public.service_usage VALUES (918, 454, 5, '2025-07-14', 3, 15000.00);
INSERT INTO public.service_usage VALUES (919, 454, 5, '2025-07-14', 1, 15000.00);
INSERT INTO public.service_usage VALUES (920, 455, 3, '2025-07-22', 1, 3500.00);
INSERT INTO public.service_usage VALUES (921, 455, 2, '2025-07-21', 2, 6000.00);
INSERT INTO public.service_usage VALUES (922, 456, 4, '2025-07-25', 2, 1800.00);
INSERT INTO public.service_usage VALUES (923, 458, 4, '2025-08-06', 3, 1800.00);
INSERT INTO public.service_usage VALUES (924, 458, 1, '2025-08-06', 2, 2500.00);
INSERT INTO public.service_usage VALUES (925, 458, 1, '2025-08-06', 2, 2500.00);
INSERT INTO public.service_usage VALUES (926, 458, 5, '2025-08-06', 3, 15000.00);
INSERT INTO public.service_usage VALUES (927, 459, 2, '2025-08-10', 3, 6000.00);
INSERT INTO public.service_usage VALUES (928, 459, 3, '2025-08-09', 2, 3500.00);
INSERT INTO public.service_usage VALUES (929, 460, 3, '2025-08-14', 3, 3500.00);
INSERT INTO public.service_usage VALUES (930, 463, 7, '2025-08-26', 2, 12000.00);
INSERT INTO public.service_usage VALUES (931, 463, 3, '2025-08-27', 3, 3500.00);
INSERT INTO public.service_usage VALUES (932, 463, 3, '2025-08-27', 2, 3500.00);
INSERT INTO public.service_usage VALUES (933, 464, 7, '2025-08-31', 3, 12000.00);
INSERT INTO public.service_usage VALUES (934, 464, 7, '2025-08-31', 2, 12000.00);
INSERT INTO public.service_usage VALUES (935, 464, 1, '2025-09-01', 2, 2500.00);
INSERT INTO public.service_usage VALUES (936, 465, 4, '2025-09-03', 3, 1800.00);
INSERT INTO public.service_usage VALUES (937, 465, 7, '2025-09-02', 4, 12000.00);
INSERT INTO public.service_usage VALUES (938, 466, 7, '2025-09-06', 1, 12000.00);
INSERT INTO public.service_usage VALUES (939, 466, 6, '2025-09-09', 1, 600.00);
INSERT INTO public.service_usage VALUES (940, 467, 6, '2025-09-12', 1, 600.00);
INSERT INTO public.service_usage VALUES (941, 467, 6, '2025-09-13', 1, 600.00);
INSERT INTO public.service_usage VALUES (942, 467, 6, '2025-09-12', 2, 600.00);
INSERT INTO public.service_usage VALUES (943, 467, 7, '2025-09-12', 2, 12000.00);
INSERT INTO public.service_usage VALUES (944, 468, 4, '2025-09-16', 2, 1800.00);
INSERT INTO public.service_usage VALUES (945, 469, 3, '2025-09-19', 3, 3500.00);
INSERT INTO public.service_usage VALUES (946, 469, 7, '2025-09-19', 4, 12000.00);
INSERT INTO public.service_usage VALUES (947, 469, 2, '2025-09-19', 3, 6000.00);
INSERT INTO public.service_usage VALUES (948, 470, 2, '2025-09-25', 1, 6000.00);
INSERT INTO public.service_usage VALUES (949, 472, 2, '2025-09-30', 1, 6000.00);
INSERT INTO public.service_usage VALUES (950, 472, 6, '2025-09-30', 1, 600.00);
INSERT INTO public.service_usage VALUES (951, 472, 1, '2025-09-30', 3, 2500.00);
INSERT INTO public.service_usage VALUES (952, 473, 6, '2025-07-01', 3, 600.00);
INSERT INTO public.service_usage VALUES (953, 474, 1, '2025-07-06', 1, 2500.00);
INSERT INTO public.service_usage VALUES (954, 474, 2, '2025-07-06', 3, 6000.00);
INSERT INTO public.service_usage VALUES (955, 475, 1, '2025-07-12', 4, 2500.00);
INSERT INTO public.service_usage VALUES (956, 475, 4, '2025-07-11', 3, 1800.00);
INSERT INTO public.service_usage VALUES (957, 475, 4, '2025-07-12', 2, 1800.00);
INSERT INTO public.service_usage VALUES (958, 475, 4, '2025-07-11', 2, 1800.00);
INSERT INTO public.service_usage VALUES (959, 477, 6, '2025-07-18', 1, 600.00);
INSERT INTO public.service_usage VALUES (960, 478, 2, '2025-07-19', 2, 6000.00);
INSERT INTO public.service_usage VALUES (961, 478, 1, '2025-07-21', 2, 2500.00);
INSERT INTO public.service_usage VALUES (962, 479, 3, '2025-07-25', 3, 3500.00);
INSERT INTO public.service_usage VALUES (963, 479, 6, '2025-07-26', 3, 600.00);
INSERT INTO public.service_usage VALUES (964, 480, 6, '2025-07-28', 2, 600.00);
INSERT INTO public.service_usage VALUES (965, 482, 1, '2025-08-06', 3, 2500.00);
INSERT INTO public.service_usage VALUES (966, 482, 7, '2025-08-05', 3, 12000.00);
INSERT INTO public.service_usage VALUES (967, 483, 5, '2025-08-14', 2, 15000.00);
INSERT INTO public.service_usage VALUES (968, 484, 3, '2025-08-19', 1, 3500.00);
INSERT INTO public.service_usage VALUES (969, 484, 4, '2025-08-19', 4, 1800.00);
INSERT INTO public.service_usage VALUES (970, 485, 7, '2025-08-26', 4, 12000.00);
INSERT INTO public.service_usage VALUES (971, 485, 2, '2025-08-27', 2, 6000.00);
INSERT INTO public.service_usage VALUES (972, 485, 3, '2025-08-27', 4, 3500.00);
INSERT INTO public.service_usage VALUES (973, 486, 3, '2025-08-29', 1, 3500.00);
INSERT INTO public.service_usage VALUES (974, 486, 3, '2025-08-30', 2, 3500.00);
INSERT INTO public.service_usage VALUES (975, 486, 6, '2025-08-30', 1, 600.00);
INSERT INTO public.service_usage VALUES (976, 488, 7, '2025-09-11', 1, 12000.00);
INSERT INTO public.service_usage VALUES (977, 488, 5, '2025-09-09', 2, 15000.00);
INSERT INTO public.service_usage VALUES (978, 488, 1, '2025-09-09', 2, 2500.00);
INSERT INTO public.service_usage VALUES (979, 489, 1, '2025-09-14', 2, 2500.00);
INSERT INTO public.service_usage VALUES (980, 489, 4, '2025-09-15', 3, 1800.00);
INSERT INTO public.service_usage VALUES (981, 489, 2, '2025-09-15', 1, 6000.00);
INSERT INTO public.service_usage VALUES (982, 490, 1, '2025-09-18', 3, 2500.00);
INSERT INTO public.service_usage VALUES (983, 490, 4, '2025-09-17', 1, 1800.00);
INSERT INTO public.service_usage VALUES (984, 490, 1, '2025-09-18', 3, 2500.00);
INSERT INTO public.service_usage VALUES (985, 491, 6, '2025-09-22', 3, 600.00);
INSERT INTO public.service_usage VALUES (986, 491, 6, '2025-09-22', 2, 600.00);
INSERT INTO public.service_usage VALUES (987, 492, 3, '2025-09-23', 2, 3500.00);
INSERT INTO public.service_usage VALUES (988, 492, 4, '2025-09-23', 3, 1800.00);
INSERT INTO public.service_usage VALUES (989, 493, 7, '2025-09-30', 2, 12000.00);
INSERT INTO public.service_usage VALUES (990, 493, 2, '2025-09-30', 3, 6000.00);
INSERT INTO public.service_usage VALUES (991, 494, 2, '2025-07-02', 1, 6000.00);
INSERT INTO public.service_usage VALUES (992, 494, 5, '2025-07-01', 3, 15000.00);
INSERT INTO public.service_usage VALUES (993, 494, 3, '2025-07-02', 2, 3500.00);
INSERT INTO public.service_usage VALUES (994, 495, 3, '2025-07-04', 1, 3500.00);
INSERT INTO public.service_usage VALUES (995, 495, 2, '2025-07-07', 2, 6000.00);
INSERT INTO public.service_usage VALUES (996, 495, 1, '2025-07-05', 2, 2500.00);
INSERT INTO public.service_usage VALUES (997, 496, 1, '2025-07-13', 2, 2500.00);
INSERT INTO public.service_usage VALUES (998, 496, 4, '2025-07-13', 2, 1800.00);
INSERT INTO public.service_usage VALUES (999, 497, 1, '2025-07-15', 4, 2500.00);
INSERT INTO public.service_usage VALUES (1000, 498, 5, '2025-07-22', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1001, 498, 3, '2025-07-21', 1, 3500.00);
INSERT INTO public.service_usage VALUES (1002, 499, 2, '2025-07-24', 1, 6000.00);
INSERT INTO public.service_usage VALUES (1003, 499, 5, '2025-07-24', 1, 15000.00);
INSERT INTO public.service_usage VALUES (1004, 499, 5, '2025-07-24', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1005, 500, 7, '2025-07-27', 2, 12000.00);
INSERT INTO public.service_usage VALUES (1006, 500, 6, '2025-07-27', 2, 600.00);
INSERT INTO public.service_usage VALUES (1007, 500, 7, '2025-07-27', 4, 12000.00);
INSERT INTO public.service_usage VALUES (1008, 500, 2, '2025-07-27', 4, 6000.00);
INSERT INTO public.service_usage VALUES (1009, 501, 4, '2025-07-30', 1, 1800.00);
INSERT INTO public.service_usage VALUES (1010, 501, 7, '2025-07-31', 3, 12000.00);
INSERT INTO public.service_usage VALUES (1011, 502, 1, '2025-08-05', 4, 2500.00);
INSERT INTO public.service_usage VALUES (1012, 503, 7, '2025-08-09', 1, 12000.00);
INSERT INTO public.service_usage VALUES (1013, 505, 3, '2025-08-16', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1014, 505, 1, '2025-08-16', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1015, 505, 6, '2025-08-17', 3, 600.00);
INSERT INTO public.service_usage VALUES (1016, 506, 1, '2025-08-22', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1017, 507, 3, '2025-08-25', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1018, 507, 6, '2025-08-26', 2, 600.00);
INSERT INTO public.service_usage VALUES (1019, 507, 4, '2025-08-25', 2, 1800.00);
INSERT INTO public.service_usage VALUES (1020, 507, 4, '2025-08-27', 2, 1800.00);
INSERT INTO public.service_usage VALUES (1021, 508, 7, '2025-08-31', 2, 12000.00);
INSERT INTO public.service_usage VALUES (1022, 508, 6, '2025-08-30', 3, 600.00);
INSERT INTO public.service_usage VALUES (1023, 508, 4, '2025-08-31', 4, 1800.00);
INSERT INTO public.service_usage VALUES (1024, 509, 4, '2025-09-01', 4, 1800.00);
INSERT INTO public.service_usage VALUES (1025, 509, 2, '2025-09-03', 2, 6000.00);
INSERT INTO public.service_usage VALUES (1026, 509, 1, '2025-09-02', 3, 2500.00);
INSERT INTO public.service_usage VALUES (1027, 511, 6, '2025-09-10', 2, 600.00);
INSERT INTO public.service_usage VALUES (1028, 511, 2, '2025-09-08', 1, 6000.00);
INSERT INTO public.service_usage VALUES (1029, 511, 3, '2025-09-09', 1, 3500.00);
INSERT INTO public.service_usage VALUES (1030, 512, 3, '2025-09-13', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1031, 512, 1, '2025-09-13', 3, 2500.00);
INSERT INTO public.service_usage VALUES (1032, 512, 1, '2025-09-12', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1033, 513, 1, '2025-09-16', 3, 2500.00);
INSERT INTO public.service_usage VALUES (1034, 514, 3, '2025-09-19', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1035, 514, 7, '2025-09-20', 2, 12000.00);
INSERT INTO public.service_usage VALUES (1036, 515, 2, '2025-09-24', 3, 6000.00);
INSERT INTO public.service_usage VALUES (1037, 516, 5, '2025-09-27', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1038, 517, 7, '2025-09-30', 2, 12000.00);
INSERT INTO public.service_usage VALUES (1039, 519, 6, '2025-07-03', 3, 600.00);
INSERT INTO public.service_usage VALUES (1040, 519, 1, '2025-07-03', 4, 2500.00);
INSERT INTO public.service_usage VALUES (1041, 520, 6, '2025-07-07', 2, 600.00);
INSERT INTO public.service_usage VALUES (1042, 520, 5, '2025-07-06', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1043, 520, 3, '2025-07-07', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1044, 521, 2, '2025-07-10', 2, 6000.00);
INSERT INTO public.service_usage VALUES (1045, 521, 3, '2025-07-11', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1046, 522, 6, '2025-07-16', 2, 600.00);
INSERT INTO public.service_usage VALUES (1047, 522, 1, '2025-07-16', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1048, 523, 3, '2025-07-18', 1, 3500.00);
INSERT INTO public.service_usage VALUES (1049, 523, 2, '2025-07-19', 3, 6000.00);
INSERT INTO public.service_usage VALUES (1050, 523, 6, '2025-07-20', 3, 600.00);
INSERT INTO public.service_usage VALUES (1051, 523, 3, '2025-07-18', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1052, 524, 2, '2025-07-22', 1, 6000.00);
INSERT INTO public.service_usage VALUES (1053, 524, 3, '2025-07-23', 1, 3500.00);
INSERT INTO public.service_usage VALUES (1054, 524, 5, '2025-07-22', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1055, 525, 3, '2025-07-24', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1056, 525, 5, '2025-07-25', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1057, 525, 4, '2025-07-25', 2, 1800.00);
INSERT INTO public.service_usage VALUES (1058, 526, 5, '2025-07-28', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1059, 526, 3, '2025-07-27', 4, 3500.00);
INSERT INTO public.service_usage VALUES (1060, 526, 3, '2025-07-30', 1, 3500.00);
INSERT INTO public.service_usage VALUES (1061, 527, 2, '2025-08-05', 1, 6000.00);
INSERT INTO public.service_usage VALUES (1062, 528, 7, '2025-08-09', 1, 12000.00);
INSERT INTO public.service_usage VALUES (1063, 529, 5, '2025-08-12', 4, 15000.00);
INSERT INTO public.service_usage VALUES (1064, 529, 1, '2025-08-12', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1065, 529, 5, '2025-08-12', 1, 15000.00);
INSERT INTO public.service_usage VALUES (1066, 530, 3, '2025-08-16', 1, 3500.00);
INSERT INTO public.service_usage VALUES (1067, 531, 2, '2025-08-19', 2, 6000.00);
INSERT INTO public.service_usage VALUES (1068, 531, 1, '2025-08-19', 3, 2500.00);
INSERT INTO public.service_usage VALUES (1069, 532, 2, '2025-08-23', 4, 6000.00);
INSERT INTO public.service_usage VALUES (1070, 532, 2, '2025-08-22', 2, 6000.00);
INSERT INTO public.service_usage VALUES (1071, 534, 2, '2025-09-03', 2, 6000.00);
INSERT INTO public.service_usage VALUES (1072, 534, 6, '2025-09-02', 2, 600.00);
INSERT INTO public.service_usage VALUES (1073, 534, 3, '2025-09-02', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1074, 534, 1, '2025-09-04', 4, 2500.00);
INSERT INTO public.service_usage VALUES (1075, 535, 3, '2025-09-07', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1076, 535, 5, '2025-09-07', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1077, 535, 4, '2025-09-06', 3, 1800.00);
INSERT INTO public.service_usage VALUES (1078, 536, 5, '2025-09-09', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1079, 537, 7, '2025-09-12', 1, 12000.00);
INSERT INTO public.service_usage VALUES (1080, 537, 2, '2025-09-14', 2, 6000.00);
INSERT INTO public.service_usage VALUES (1081, 537, 5, '2025-09-11', 1, 15000.00);
INSERT INTO public.service_usage VALUES (1082, 538, 5, '2025-09-16', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1083, 538, 4, '2025-09-16', 2, 1800.00);
INSERT INTO public.service_usage VALUES (1084, 539, 7, '2025-09-20', 1, 12000.00);
INSERT INTO public.service_usage VALUES (1085, 539, 1, '2025-09-19', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1086, 540, 6, '2025-09-25', 3, 600.00);
INSERT INTO public.service_usage VALUES (1087, 540, 6, '2025-09-24', 2, 600.00);
INSERT INTO public.service_usage VALUES (1088, 540, 4, '2025-09-24', 2, 1800.00);
INSERT INTO public.service_usage VALUES (1089, 540, 4, '2025-09-25', 3, 1800.00);
INSERT INTO public.service_usage VALUES (1090, 541, 5, '2025-09-28', 4, 15000.00);
INSERT INTO public.service_usage VALUES (1091, 542, 5, '2025-09-30', 1, 15000.00);
INSERT INTO public.service_usage VALUES (1092, 542, 1, '2025-10-02', 4, 2500.00);
INSERT INTO public.service_usage VALUES (1093, 542, 6, '2025-09-30', 2, 600.00);
INSERT INTO public.service_usage VALUES (1094, 542, 4, '2025-10-02', 3, 1800.00);
INSERT INTO public.service_usage VALUES (1095, 543, 4, '2025-07-02', 2, 1800.00);
INSERT INTO public.service_usage VALUES (1096, 544, 6, '2025-07-05', 3, 600.00);
INSERT INTO public.service_usage VALUES (1097, 544, 7, '2025-07-05', 2, 12000.00);
INSERT INTO public.service_usage VALUES (1098, 544, 1, '2025-07-05', 3, 2500.00);
INSERT INTO public.service_usage VALUES (1099, 545, 1, '2025-07-06', 3, 2500.00);
INSERT INTO public.service_usage VALUES (1100, 545, 6, '2025-07-06', 3, 600.00);
INSERT INTO public.service_usage VALUES (1101, 546, 6, '2025-07-09', 3, 600.00);
INSERT INTO public.service_usage VALUES (1102, 546, 7, '2025-07-10', 4, 12000.00);
INSERT INTO public.service_usage VALUES (1103, 546, 7, '2025-07-08', 2, 12000.00);
INSERT INTO public.service_usage VALUES (1104, 547, 3, '2025-07-13', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1105, 547, 3, '2025-07-14', 4, 3500.00);
INSERT INTO public.service_usage VALUES (1106, 547, 1, '2025-07-14', 1, 2500.00);
INSERT INTO public.service_usage VALUES (1107, 547, 6, '2025-07-13', 3, 600.00);
INSERT INTO public.service_usage VALUES (1108, 548, 1, '2025-07-17', 4, 2500.00);
INSERT INTO public.service_usage VALUES (1109, 549, 5, '2025-07-19', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1110, 549, 3, '2025-07-19', 4, 3500.00);
INSERT INTO public.service_usage VALUES (1111, 549, 4, '2025-07-19', 3, 1800.00);
INSERT INTO public.service_usage VALUES (1112, 550, 4, '2025-07-22', 2, 1800.00);
INSERT INTO public.service_usage VALUES (1113, 550, 4, '2025-07-22', 2, 1800.00);
INSERT INTO public.service_usage VALUES (1114, 551, 4, '2025-07-25', 2, 1800.00);
INSERT INTO public.service_usage VALUES (1115, 552, 4, '2025-07-28', 2, 1800.00);
INSERT INTO public.service_usage VALUES (1116, 553, 6, '2025-08-03', 3, 600.00);
INSERT INTO public.service_usage VALUES (1117, 553, 3, '2025-08-03', 1, 3500.00);
INSERT INTO public.service_usage VALUES (1118, 554, 6, '2025-08-07', 1, 600.00);
INSERT INTO public.service_usage VALUES (1119, 554, 3, '2025-08-07', 4, 3500.00);
INSERT INTO public.service_usage VALUES (1120, 554, 7, '2025-08-07', 1, 12000.00);
INSERT INTO public.service_usage VALUES (1121, 555, 3, '2025-08-10', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1122, 556, 6, '2025-08-14', 4, 600.00);
INSERT INTO public.service_usage VALUES (1123, 556, 3, '2025-08-16', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1124, 557, 3, '2025-08-19', 1, 3500.00);
INSERT INTO public.service_usage VALUES (1125, 558, 6, '2025-08-25', 1, 600.00);
INSERT INTO public.service_usage VALUES (1126, 558, 7, '2025-08-25', 2, 12000.00);
INSERT INTO public.service_usage VALUES (1127, 558, 2, '2025-08-25', 4, 6000.00);
INSERT INTO public.service_usage VALUES (1128, 558, 6, '2025-08-25', 4, 600.00);
INSERT INTO public.service_usage VALUES (1129, 560, 6, '2025-08-30', 3, 600.00);
INSERT INTO public.service_usage VALUES (1130, 560, 6, '2025-08-30', 1, 600.00);
INSERT INTO public.service_usage VALUES (1131, 560, 2, '2025-08-30', 2, 6000.00);
INSERT INTO public.service_usage VALUES (1132, 560, 5, '2025-08-30', 4, 15000.00);
INSERT INTO public.service_usage VALUES (1133, 561, 3, '2025-09-02', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1134, 562, 7, '2025-09-08', 3, 12000.00);
INSERT INTO public.service_usage VALUES (1135, 562, 3, '2025-09-07', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1136, 564, 5, '2025-09-15', 4, 15000.00);
INSERT INTO public.service_usage VALUES (1137, 564, 1, '2025-09-15', 1, 2500.00);
INSERT INTO public.service_usage VALUES (1138, 565, 6, '2025-09-23', 1, 600.00);
INSERT INTO public.service_usage VALUES (1139, 565, 2, '2025-09-22', 1, 6000.00);
INSERT INTO public.service_usage VALUES (1140, 566, 7, '2025-09-24', 2, 12000.00);
INSERT INTO public.service_usage VALUES (1141, 566, 1, '2025-09-24', 3, 2500.00);
INSERT INTO public.service_usage VALUES (1142, 567, 3, '2025-09-29', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1143, 567, 7, '2025-09-28', 2, 12000.00);
INSERT INTO public.service_usage VALUES (1144, 567, 3, '2025-09-28', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1145, 567, 1, '2025-09-29', 4, 2500.00);
INSERT INTO public.service_usage VALUES (1146, 568, 4, '2025-07-05', 1, 1800.00);
INSERT INTO public.service_usage VALUES (1147, 568, 3, '2025-07-02', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1148, 568, 4, '2025-07-03', 3, 1800.00);
INSERT INTO public.service_usage VALUES (1149, 569, 2, '2025-07-07', 4, 6000.00);
INSERT INTO public.service_usage VALUES (1150, 569, 1, '2025-07-08', 3, 2500.00);
INSERT INTO public.service_usage VALUES (1151, 569, 4, '2025-07-07', 1, 1800.00);
INSERT INTO public.service_usage VALUES (1152, 569, 5, '2025-07-07', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1153, 570, 1, '2025-07-12', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1154, 570, 1, '2025-07-11', 3, 2500.00);
INSERT INTO public.service_usage VALUES (1155, 570, 3, '2025-07-11', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1156, 571, 1, '2025-07-15', 3, 2500.00);
INSERT INTO public.service_usage VALUES (1157, 571, 4, '2025-07-16', 2, 1800.00);
INSERT INTO public.service_usage VALUES (1158, 572, 6, '2025-07-19', 2, 600.00);
INSERT INTO public.service_usage VALUES (1159, 572, 3, '2025-07-19', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1160, 572, 2, '2025-07-19', 4, 6000.00);
INSERT INTO public.service_usage VALUES (1161, 573, 1, '2025-07-22', 4, 2500.00);
INSERT INTO public.service_usage VALUES (1162, 573, 5, '2025-07-22', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1163, 574, 6, '2025-07-25', 4, 600.00);
INSERT INTO public.service_usage VALUES (1164, 575, 5, '2025-07-31', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1165, 575, 6, '2025-08-01', 2, 600.00);
INSERT INTO public.service_usage VALUES (1166, 576, 7, '2025-08-04', 3, 12000.00);
INSERT INTO public.service_usage VALUES (1167, 577, 7, '2025-08-08', 4, 12000.00);
INSERT INTO public.service_usage VALUES (1168, 578, 2, '2025-08-11', 1, 6000.00);
INSERT INTO public.service_usage VALUES (1169, 579, 5, '2025-08-15', 4, 15000.00);
INSERT INTO public.service_usage VALUES (1170, 580, 5, '2025-08-20', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1171, 580, 6, '2025-08-20', 2, 600.00);
INSERT INTO public.service_usage VALUES (1172, 581, 1, '2025-08-27', 3, 2500.00);
INSERT INTO public.service_usage VALUES (1173, 581, 7, '2025-08-28', 3, 12000.00);
INSERT INTO public.service_usage VALUES (1174, 582, 6, '2025-08-31', 3, 600.00);
INSERT INTO public.service_usage VALUES (1175, 582, 5, '2025-08-30', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1176, 582, 5, '2025-08-30', 1, 15000.00);
INSERT INTO public.service_usage VALUES (1177, 583, 7, '2025-09-02', 3, 12000.00);
INSERT INTO public.service_usage VALUES (1178, 583, 3, '2025-09-03', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1179, 584, 1, '2025-09-06', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1180, 584, 1, '2025-09-06', 4, 2500.00);
INSERT INTO public.service_usage VALUES (1181, 584, 3, '2025-09-07', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1182, 584, 1, '2025-09-05', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1183, 587, 2, '2025-09-17', 1, 6000.00);
INSERT INTO public.service_usage VALUES (1184, 587, 1, '2025-09-18', 1, 2500.00);
INSERT INTO public.service_usage VALUES (1185, 588, 7, '2025-09-21', 3, 12000.00);
INSERT INTO public.service_usage VALUES (1186, 588, 2, '2025-09-21', 3, 6000.00);
INSERT INTO public.service_usage VALUES (1187, 588, 6, '2025-09-21', 3, 600.00);
INSERT INTO public.service_usage VALUES (1188, 589, 2, '2025-09-22', 1, 6000.00);
INSERT INTO public.service_usage VALUES (1189, 589, 7, '2025-09-22', 3, 12000.00);
INSERT INTO public.service_usage VALUES (1190, 589, 2, '2025-09-23', 4, 6000.00);
INSERT INTO public.service_usage VALUES (1191, 590, 2, '2025-09-26', 2, 6000.00);
INSERT INTO public.service_usage VALUES (1192, 590, 6, '2025-09-27', 1, 600.00);
INSERT INTO public.service_usage VALUES (1193, 591, 1, '2025-10-01', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1194, 592, 7, '2025-07-02', 4, 12000.00);
INSERT INTO public.service_usage VALUES (1195, 592, 2, '2025-07-02', 3, 6000.00);
INSERT INTO public.service_usage VALUES (1196, 592, 6, '2025-07-01', 2, 600.00);
INSERT INTO public.service_usage VALUES (1197, 592, 1, '2025-07-02', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1198, 593, 4, '2025-07-08', 2, 1800.00);
INSERT INTO public.service_usage VALUES (1199, 593, 5, '2025-07-08', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1200, 594, 5, '2025-07-13', 4, 15000.00);
INSERT INTO public.service_usage VALUES (1201, 595, 7, '2025-07-18', 2, 12000.00);
INSERT INTO public.service_usage VALUES (1202, 595, 6, '2025-07-17', 4, 600.00);
INSERT INTO public.service_usage VALUES (1203, 595, 5, '2025-07-19', 4, 15000.00);
INSERT INTO public.service_usage VALUES (1204, 596, 7, '2025-07-24', 2, 12000.00);
INSERT INTO public.service_usage VALUES (1205, 597, 6, '2025-07-29', 4, 600.00);
INSERT INTO public.service_usage VALUES (1206, 597, 3, '2025-07-29', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1207, 598, 6, '2025-08-02', 3, 600.00);
INSERT INTO public.service_usage VALUES (1208, 598, 5, '2025-08-02', 4, 15000.00);
INSERT INTO public.service_usage VALUES (1209, 598, 1, '2025-08-03', 1, 2500.00);
INSERT INTO public.service_usage VALUES (1210, 599, 5, '2025-08-07', 1, 15000.00);
INSERT INTO public.service_usage VALUES (1211, 599, 2, '2025-08-07', 1, 6000.00);
INSERT INTO public.service_usage VALUES (1212, 600, 6, '2025-08-12', 4, 600.00);
INSERT INTO public.service_usage VALUES (1213, 600, 3, '2025-08-10', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1214, 601, 7, '2025-08-15', 3, 12000.00);
INSERT INTO public.service_usage VALUES (1215, 601, 3, '2025-08-16', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1216, 601, 2, '2025-08-17', 3, 6000.00);
INSERT INTO public.service_usage VALUES (1217, 602, 4, '2025-08-20', 2, 1800.00);
INSERT INTO public.service_usage VALUES (1218, 602, 3, '2025-08-20', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1219, 602, 5, '2025-08-22', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1220, 603, 5, '2025-08-26', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1221, 603, 5, '2025-08-26', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1222, 604, 5, '2025-08-31', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1223, 605, 3, '2025-09-03', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1224, 606, 5, '2025-09-05', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1225, 607, 1, '2025-09-10', 4, 2500.00);
INSERT INTO public.service_usage VALUES (1226, 607, 7, '2025-09-10', 3, 12000.00);
INSERT INTO public.service_usage VALUES (1227, 608, 3, '2025-09-14', 4, 3500.00);
INSERT INTO public.service_usage VALUES (1228, 610, 1, '2025-09-20', 1, 2500.00);
INSERT INTO public.service_usage VALUES (1229, 610, 5, '2025-09-20', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1230, 610, 3, '2025-09-20', 1, 3500.00);
INSERT INTO public.service_usage VALUES (1231, 610, 6, '2025-09-20', 1, 600.00);
INSERT INTO public.service_usage VALUES (1232, 611, 5, '2025-09-23', 4, 15000.00);
INSERT INTO public.service_usage VALUES (1233, 611, 7, '2025-09-23', 3, 12000.00);
INSERT INTO public.service_usage VALUES (1234, 611, 5, '2025-09-23', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1235, 612, 5, '2025-09-28', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1236, 613, 5, '2025-09-30', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1237, 614, 4, '2025-07-02', 2, 1800.00);
INSERT INTO public.service_usage VALUES (1238, 614, 4, '2025-07-04', 1, 1800.00);
INSERT INTO public.service_usage VALUES (1239, 615, 7, '2025-07-09', 1, 12000.00);
INSERT INTO public.service_usage VALUES (1240, 615, 1, '2025-07-08', 3, 2500.00);
INSERT INTO public.service_usage VALUES (1241, 615, 5, '2025-07-09', 4, 15000.00);
INSERT INTO public.service_usage VALUES (1242, 616, 4, '2025-07-15', 2, 1800.00);
INSERT INTO public.service_usage VALUES (1243, 616, 2, '2025-07-15', 4, 6000.00);
INSERT INTO public.service_usage VALUES (1244, 617, 4, '2025-07-19', 3, 1800.00);
INSERT INTO public.service_usage VALUES (1245, 617, 1, '2025-07-18', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1246, 617, 7, '2025-07-18', 4, 12000.00);
INSERT INTO public.service_usage VALUES (1247, 618, 6, '2025-07-21', 2, 600.00);
INSERT INTO public.service_usage VALUES (1248, 619, 3, '2025-07-24', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1249, 619, 6, '2025-07-24', 2, 600.00);
INSERT INTO public.service_usage VALUES (1250, 619, 1, '2025-07-25', 4, 2500.00);
INSERT INTO public.service_usage VALUES (1251, 621, 5, '2025-07-30', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1252, 621, 5, '2025-07-30', 4, 15000.00);
INSERT INTO public.service_usage VALUES (1253, 621, 1, '2025-08-01', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1254, 622, 1, '2025-08-03', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1255, 623, 5, '2025-08-12', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1256, 623, 3, '2025-08-11', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1257, 623, 7, '2025-08-09', 3, 12000.00);
INSERT INTO public.service_usage VALUES (1258, 624, 1, '2025-08-16', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1259, 624, 4, '2025-08-15', 1, 1800.00);
INSERT INTO public.service_usage VALUES (1260, 625, 3, '2025-08-19', 1, 3500.00);
INSERT INTO public.service_usage VALUES (1261, 626, 4, '2025-08-21', 2, 1800.00);
INSERT INTO public.service_usage VALUES (1262, 627, 2, '2025-08-22', 1, 6000.00);
INSERT INTO public.service_usage VALUES (1263, 628, 1, '2025-08-26', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1264, 628, 6, '2025-08-27', 2, 600.00);
INSERT INTO public.service_usage VALUES (1265, 629, 2, '2025-08-30', 1, 6000.00);
INSERT INTO public.service_usage VALUES (1266, 630, 5, '2025-09-07', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1267, 630, 3, '2025-09-04', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1268, 632, 7, '2025-09-12', 1, 12000.00);
INSERT INTO public.service_usage VALUES (1269, 632, 2, '2025-09-12', 3, 6000.00);
INSERT INTO public.service_usage VALUES (1270, 632, 7, '2025-09-12', 4, 12000.00);
INSERT INTO public.service_usage VALUES (1271, 633, 2, '2025-09-17', 2, 6000.00);
INSERT INTO public.service_usage VALUES (1272, 633, 1, '2025-09-16', 3, 2500.00);
INSERT INTO public.service_usage VALUES (1273, 634, 2, '2025-09-21', 3, 6000.00);
INSERT INTO public.service_usage VALUES (1274, 635, 6, '2025-09-25', 3, 600.00);
INSERT INTO public.service_usage VALUES (1275, 635, 3, '2025-09-27', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1276, 635, 6, '2025-09-28', 4, 600.00);
INSERT INTO public.service_usage VALUES (1277, 636, 6, '2025-09-30', 2, 600.00);
INSERT INTO public.service_usage VALUES (1278, 636, 7, '2025-10-04', 1, 12000.00);
INSERT INTO public.service_usage VALUES (1279, 636, 5, '2025-10-02', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1280, 637, 5, '2025-07-02', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1281, 637, 3, '2025-07-01', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1282, 637, 5, '2025-07-02', 4, 15000.00);
INSERT INTO public.service_usage VALUES (1283, 638, 7, '2025-07-05', 4, 12000.00);
INSERT INTO public.service_usage VALUES (1284, 638, 4, '2025-07-04', 4, 1800.00);
INSERT INTO public.service_usage VALUES (1285, 638, 3, '2025-07-05', 1, 3500.00);
INSERT INTO public.service_usage VALUES (1286, 639, 2, '2025-07-10', 3, 6000.00);
INSERT INTO public.service_usage VALUES (1287, 639, 3, '2025-07-10', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1288, 641, 2, '2025-07-18', 4, 6000.00);
INSERT INTO public.service_usage VALUES (1289, 641, 1, '2025-07-18', 4, 2500.00);
INSERT INTO public.service_usage VALUES (1290, 641, 3, '2025-07-20', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1291, 641, 5, '2025-07-19', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1292, 642, 1, '2025-07-23', 3, 2500.00);
INSERT INTO public.service_usage VALUES (1293, 642, 5, '2025-07-25', 4, 15000.00);
INSERT INTO public.service_usage VALUES (1294, 642, 7, '2025-07-24', 4, 12000.00);
INSERT INTO public.service_usage VALUES (1295, 643, 1, '2025-07-29', 4, 2500.00);
INSERT INTO public.service_usage VALUES (1296, 643, 7, '2025-07-28', 3, 12000.00);
INSERT INTO public.service_usage VALUES (1297, 643, 4, '2025-07-28', 2, 1800.00);
INSERT INTO public.service_usage VALUES (1298, 645, 1, '2025-08-04', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1299, 646, 1, '2025-08-06', 1, 2500.00);
INSERT INTO public.service_usage VALUES (1300, 646, 5, '2025-08-06', 1, 15000.00);
INSERT INTO public.service_usage VALUES (1301, 647, 4, '2025-08-08', 1, 1800.00);
INSERT INTO public.service_usage VALUES (1302, 647, 3, '2025-08-08', 1, 3500.00);
INSERT INTO public.service_usage VALUES (1303, 647, 5, '2025-08-08', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1304, 648, 1, '2025-08-11', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1305, 648, 5, '2025-08-11', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1306, 648, 3, '2025-08-11', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1307, 648, 7, '2025-08-11', 1, 12000.00);
INSERT INTO public.service_usage VALUES (1308, 649, 5, '2025-08-13', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1309, 649, 4, '2025-08-15', 3, 1800.00);
INSERT INTO public.service_usage VALUES (1310, 650, 6, '2025-08-19', 2, 600.00);
INSERT INTO public.service_usage VALUES (1311, 650, 2, '2025-08-19', 1, 6000.00);
INSERT INTO public.service_usage VALUES (1312, 651, 4, '2025-08-20', 2, 1800.00);
INSERT INTO public.service_usage VALUES (1313, 651, 4, '2025-08-20', 3, 1800.00);
INSERT INTO public.service_usage VALUES (1314, 651, 6, '2025-08-20', 3, 600.00);
INSERT INTO public.service_usage VALUES (1315, 652, 6, '2025-08-23', 1, 600.00);
INSERT INTO public.service_usage VALUES (1316, 652, 2, '2025-08-23', 3, 6000.00);
INSERT INTO public.service_usage VALUES (1317, 653, 3, '2025-08-27', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1318, 654, 1, '2025-08-31', 3, 2500.00);
INSERT INTO public.service_usage VALUES (1319, 654, 5, '2025-08-31', 1, 15000.00);
INSERT INTO public.service_usage VALUES (1320, 655, 2, '2025-09-04', 1, 6000.00);
INSERT INTO public.service_usage VALUES (1321, 655, 6, '2025-09-03', 3, 600.00);
INSERT INTO public.service_usage VALUES (1322, 655, 3, '2025-09-04', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1323, 655, 3, '2025-09-04', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1324, 656, 4, '2025-09-06', 1, 1800.00);
INSERT INTO public.service_usage VALUES (1325, 656, 5, '2025-09-07', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1326, 656, 1, '2025-09-06', 4, 2500.00);
INSERT INTO public.service_usage VALUES (1327, 656, 4, '2025-09-07', 3, 1800.00);
INSERT INTO public.service_usage VALUES (1328, 657, 3, '2025-09-11', 1, 3500.00);
INSERT INTO public.service_usage VALUES (1329, 658, 4, '2025-09-15', 1, 1800.00);
INSERT INTO public.service_usage VALUES (1330, 658, 2, '2025-09-14', 4, 6000.00);
INSERT INTO public.service_usage VALUES (1331, 660, 3, '2025-09-26', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1332, 660, 3, '2025-09-27', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1333, 660, 2, '2025-09-25', 2, 6000.00);
INSERT INTO public.service_usage VALUES (1334, 661, 6, '2025-10-04', 4, 600.00);
INSERT INTO public.service_usage VALUES (1335, 661, 7, '2025-09-30', 2, 12000.00);
INSERT INTO public.service_usage VALUES (1336, 662, 6, '2025-07-01', 3, 600.00);
INSERT INTO public.service_usage VALUES (1337, 662, 1, '2025-07-02', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1338, 662, 5, '2025-07-02', 4, 15000.00);
INSERT INTO public.service_usage VALUES (1339, 663, 3, '2025-07-04', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1340, 663, 3, '2025-07-04', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1341, 663, 2, '2025-07-03', 3, 6000.00);
INSERT INTO public.service_usage VALUES (1342, 663, 6, '2025-07-04', 2, 600.00);
INSERT INTO public.service_usage VALUES (1343, 664, 2, '2025-07-07', 3, 6000.00);
INSERT INTO public.service_usage VALUES (1344, 664, 6, '2025-07-07', 3, 600.00);
INSERT INTO public.service_usage VALUES (1345, 664, 7, '2025-07-07', 4, 12000.00);
INSERT INTO public.service_usage VALUES (1346, 665, 2, '2025-07-12', 3, 6000.00);
INSERT INTO public.service_usage VALUES (1347, 665, 4, '2025-07-11', 3, 1800.00);
INSERT INTO public.service_usage VALUES (1348, 666, 6, '2025-07-17', 4, 600.00);
INSERT INTO public.service_usage VALUES (1349, 666, 6, '2025-07-17', 3, 600.00);
INSERT INTO public.service_usage VALUES (1350, 666, 6, '2025-07-17', 1, 600.00);
INSERT INTO public.service_usage VALUES (1351, 667, 4, '2025-07-22', 3, 1800.00);
INSERT INTO public.service_usage VALUES (1352, 667, 4, '2025-07-22', 4, 1800.00);
INSERT INTO public.service_usage VALUES (1353, 668, 6, '2025-07-25', 3, 600.00);
INSERT INTO public.service_usage VALUES (1354, 669, 4, '2025-07-27', 1, 1800.00);
INSERT INTO public.service_usage VALUES (1355, 670, 2, '2025-07-29', 4, 6000.00);
INSERT INTO public.service_usage VALUES (1356, 670, 2, '2025-07-29', 1, 6000.00);
INSERT INTO public.service_usage VALUES (1357, 671, 3, '2025-08-01', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1358, 671, 1, '2025-08-02', 4, 2500.00);
INSERT INTO public.service_usage VALUES (1359, 672, 3, '2025-08-04', 1, 3500.00);
INSERT INTO public.service_usage VALUES (1360, 672, 1, '2025-08-04', 1, 2500.00);
INSERT INTO public.service_usage VALUES (1361, 672, 5, '2025-08-04', 1, 15000.00);
INSERT INTO public.service_usage VALUES (1362, 672, 4, '2025-08-04', 3, 1800.00);
INSERT INTO public.service_usage VALUES (1363, 673, 5, '2025-08-07', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1364, 673, 1, '2025-08-08', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1365, 674, 5, '2025-08-14', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1366, 674, 5, '2025-08-14', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1367, 674, 7, '2025-08-14', 4, 12000.00);
INSERT INTO public.service_usage VALUES (1368, 675, 1, '2025-08-19', 3, 2500.00);
INSERT INTO public.service_usage VALUES (1369, 675, 6, '2025-08-18', 4, 600.00);
INSERT INTO public.service_usage VALUES (1370, 675, 4, '2025-08-20', 1, 1800.00);
INSERT INTO public.service_usage VALUES (1371, 675, 6, '2025-08-18', 3, 600.00);
INSERT INTO public.service_usage VALUES (1372, 676, 3, '2025-08-21', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1373, 676, 1, '2025-08-21', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1374, 677, 2, '2025-08-29', 4, 6000.00);
INSERT INTO public.service_usage VALUES (1375, 677, 5, '2025-08-28', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1376, 677, 1, '2025-08-26', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1377, 678, 2, '2025-08-31', 4, 6000.00);
INSERT INTO public.service_usage VALUES (1378, 678, 2, '2025-08-31', 4, 6000.00);
INSERT INTO public.service_usage VALUES (1379, 679, 6, '2025-09-04', 1, 600.00);
INSERT INTO public.service_usage VALUES (1380, 679, 3, '2025-09-04', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1381, 680, 3, '2025-09-08', 4, 3500.00);
INSERT INTO public.service_usage VALUES (1382, 681, 3, '2025-09-12', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1383, 681, 2, '2025-09-12', 3, 6000.00);
INSERT INTO public.service_usage VALUES (1384, 681, 6, '2025-09-12', 1, 600.00);
INSERT INTO public.service_usage VALUES (1385, 681, 5, '2025-09-12', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1386, 682, 6, '2025-09-19', 4, 600.00);
INSERT INTO public.service_usage VALUES (1387, 684, 6, '2025-09-26', 2, 600.00);
INSERT INTO public.service_usage VALUES (1388, 685, 5, '2025-09-30', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1389, 685, 3, '2025-09-28', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1390, 686, 5, '2025-07-02', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1391, 687, 2, '2025-07-03', 3, 6000.00);
INSERT INTO public.service_usage VALUES (1392, 687, 3, '2025-07-03', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1393, 687, 3, '2025-07-03', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1394, 687, 4, '2025-07-03', 2, 1800.00);
INSERT INTO public.service_usage VALUES (1395, 688, 2, '2025-07-07', 4, 6000.00);
INSERT INTO public.service_usage VALUES (1396, 688, 5, '2025-07-06', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1397, 689, 7, '2025-07-11', 3, 12000.00);
INSERT INTO public.service_usage VALUES (1398, 689, 4, '2025-07-13', 2, 1800.00);
INSERT INTO public.service_usage VALUES (1399, 690, 2, '2025-07-15', 4, 6000.00);
INSERT INTO public.service_usage VALUES (1400, 690, 5, '2025-07-15', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1401, 691, 4, '2025-07-18', 2, 1800.00);
INSERT INTO public.service_usage VALUES (1402, 692, 1, '2025-07-23', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1403, 693, 5, '2025-07-28', 1, 15000.00);
INSERT INTO public.service_usage VALUES (1404, 693, 4, '2025-07-28', 4, 1800.00);
INSERT INTO public.service_usage VALUES (1405, 695, 7, '2025-08-05', 1, 12000.00);
INSERT INTO public.service_usage VALUES (1406, 695, 1, '2025-08-07', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1407, 695, 3, '2025-08-07', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1408, 695, 7, '2025-08-06', 3, 12000.00);
INSERT INTO public.service_usage VALUES (1409, 697, 7, '2025-08-15', 3, 12000.00);
INSERT INTO public.service_usage VALUES (1410, 698, 3, '2025-08-19', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1411, 698, 6, '2025-08-19', 1, 600.00);
INSERT INTO public.service_usage VALUES (1412, 699, 2, '2025-08-22', 3, 6000.00);
INSERT INTO public.service_usage VALUES (1413, 699, 7, '2025-08-23', 3, 12000.00);
INSERT INTO public.service_usage VALUES (1414, 700, 6, '2025-08-25', 3, 600.00);
INSERT INTO public.service_usage VALUES (1415, 700, 5, '2025-08-27', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1416, 703, 2, '2025-09-09', 3, 6000.00);
INSERT INTO public.service_usage VALUES (1417, 704, 4, '2025-09-15', 3, 1800.00);
INSERT INTO public.service_usage VALUES (1418, 705, 2, '2025-09-18', 2, 6000.00);
INSERT INTO public.service_usage VALUES (1419, 706, 5, '2025-09-23', 4, 15000.00);
INSERT INTO public.service_usage VALUES (1420, 707, 2, '2025-09-28', 4, 6000.00);
INSERT INTO public.service_usage VALUES (1421, 708, 3, '2025-07-02', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1422, 709, 6, '2025-07-05', 2, 600.00);
INSERT INTO public.service_usage VALUES (1423, 709, 3, '2025-07-05', 1, 3500.00);
INSERT INTO public.service_usage VALUES (1424, 709, 1, '2025-07-04', 3, 2500.00);
INSERT INTO public.service_usage VALUES (1425, 710, 5, '2025-07-10', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1426, 711, 4, '2025-07-16', 1, 1800.00);
INSERT INTO public.service_usage VALUES (1427, 713, 1, '2025-07-29', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1428, 713, 3, '2025-07-30', 4, 3500.00);
INSERT INTO public.service_usage VALUES (1429, 713, 4, '2025-07-30', 3, 1800.00);
INSERT INTO public.service_usage VALUES (1430, 714, 3, '2025-08-02', 4, 3500.00);
INSERT INTO public.service_usage VALUES (1431, 714, 4, '2025-08-02', 4, 1800.00);
INSERT INTO public.service_usage VALUES (1432, 714, 6, '2025-08-02', 3, 600.00);
INSERT INTO public.service_usage VALUES (1433, 714, 3, '2025-08-02', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1434, 715, 4, '2025-08-07', 3, 1800.00);
INSERT INTO public.service_usage VALUES (1435, 715, 6, '2025-08-05', 2, 600.00);
INSERT INTO public.service_usage VALUES (1436, 715, 3, '2025-08-06', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1437, 717, 3, '2025-08-12', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1438, 718, 5, '2025-08-17', 4, 15000.00);
INSERT INTO public.service_usage VALUES (1439, 719, 5, '2025-08-24', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1440, 721, 6, '2025-09-01', 2, 600.00);
INSERT INTO public.service_usage VALUES (1441, 721, 6, '2025-09-01', 3, 600.00);
INSERT INTO public.service_usage VALUES (1442, 721, 1, '2025-09-02', 4, 2500.00);
INSERT INTO public.service_usage VALUES (1443, 722, 4, '2025-09-05', 4, 1800.00);
INSERT INTO public.service_usage VALUES (1444, 722, 2, '2025-09-06', 2, 6000.00);
INSERT INTO public.service_usage VALUES (1445, 722, 4, '2025-09-07', 3, 1800.00);
INSERT INTO public.service_usage VALUES (1446, 722, 4, '2025-09-07', 2, 1800.00);
INSERT INTO public.service_usage VALUES (1447, 723, 7, '2025-09-11', 3, 12000.00);
INSERT INTO public.service_usage VALUES (1448, 724, 1, '2025-09-16', 3, 2500.00);
INSERT INTO public.service_usage VALUES (1449, 725, 5, '2025-09-22', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1450, 725, 4, '2025-09-21', 3, 1800.00);
INSERT INTO public.service_usage VALUES (1451, 725, 4, '2025-09-21', 2, 1800.00);
INSERT INTO public.service_usage VALUES (1452, 726, 3, '2025-09-26', 1, 3500.00);
INSERT INTO public.service_usage VALUES (1453, 727, 5, '2025-07-02', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1454, 727, 5, '2025-07-01', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1455, 728, 2, '2025-07-04', 3, 6000.00);
INSERT INTO public.service_usage VALUES (1456, 728, 3, '2025-07-04', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1457, 730, 3, '2025-07-13', 1, 3500.00);
INSERT INTO public.service_usage VALUES (1458, 730, 2, '2025-07-13', 4, 6000.00);
INSERT INTO public.service_usage VALUES (1459, 730, 7, '2025-07-13', 2, 12000.00);
INSERT INTO public.service_usage VALUES (1460, 731, 3, '2025-07-16', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1461, 731, 5, '2025-07-14', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1462, 731, 1, '2025-07-15', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1463, 731, 1, '2025-07-14', 3, 2500.00);
INSERT INTO public.service_usage VALUES (1464, 732, 1, '2025-07-19', 1, 2500.00);
INSERT INTO public.service_usage VALUES (1465, 732, 4, '2025-07-19', 3, 1800.00);
INSERT INTO public.service_usage VALUES (1466, 733, 2, '2025-07-21', 3, 6000.00);
INSERT INTO public.service_usage VALUES (1467, 733, 4, '2025-07-22', 3, 1800.00);
INSERT INTO public.service_usage VALUES (1468, 733, 1, '2025-07-22', 1, 2500.00);
INSERT INTO public.service_usage VALUES (1469, 734, 4, '2025-07-26', 3, 1800.00);
INSERT INTO public.service_usage VALUES (1470, 735, 4, '2025-07-30', 3, 1800.00);
INSERT INTO public.service_usage VALUES (1471, 737, 1, '2025-08-07', 1, 2500.00);
INSERT INTO public.service_usage VALUES (1472, 737, 7, '2025-08-07', 4, 12000.00);
INSERT INTO public.service_usage VALUES (1473, 737, 2, '2025-08-07', 1, 6000.00);
INSERT INTO public.service_usage VALUES (1474, 738, 6, '2025-08-09', 3, 600.00);
INSERT INTO public.service_usage VALUES (1475, 738, 4, '2025-08-09', 1, 1800.00);
INSERT INTO public.service_usage VALUES (1476, 738, 6, '2025-08-09', 2, 600.00);
INSERT INTO public.service_usage VALUES (1477, 739, 6, '2025-08-13', 2, 600.00);
INSERT INTO public.service_usage VALUES (1478, 739, 1, '2025-08-11', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1479, 739, 2, '2025-08-12', 2, 6000.00);
INSERT INTO public.service_usage VALUES (1480, 740, 6, '2025-08-15', 4, 600.00);
INSERT INTO public.service_usage VALUES (1481, 740, 2, '2025-08-19', 4, 6000.00);
INSERT INTO public.service_usage VALUES (1482, 740, 4, '2025-08-18', 4, 1800.00);
INSERT INTO public.service_usage VALUES (1483, 741, 4, '2025-08-22', 3, 1800.00);
INSERT INTO public.service_usage VALUES (1484, 741, 5, '2025-08-22', 1, 15000.00);
INSERT INTO public.service_usage VALUES (1485, 742, 7, '2025-08-25', 1, 12000.00);
INSERT INTO public.service_usage VALUES (1486, 742, 5, '2025-08-25', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1487, 742, 2, '2025-08-24', 4, 6000.00);
INSERT INTO public.service_usage VALUES (1488, 743, 4, '2025-08-28', 3, 1800.00);
INSERT INTO public.service_usage VALUES (1489, 743, 2, '2025-08-28', 3, 6000.00);
INSERT INTO public.service_usage VALUES (1490, 744, 4, '2025-09-01', 2, 1800.00);
INSERT INTO public.service_usage VALUES (1491, 744, 3, '2025-09-02', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1492, 745, 7, '2025-09-06', 2, 12000.00);
INSERT INTO public.service_usage VALUES (1493, 745, 5, '2025-09-05', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1494, 746, 1, '2025-09-07', 3, 2500.00);
INSERT INTO public.service_usage VALUES (1495, 746, 6, '2025-09-07', 3, 600.00);
INSERT INTO public.service_usage VALUES (1496, 746, 6, '2025-09-08', 3, 600.00);
INSERT INTO public.service_usage VALUES (1497, 747, 5, '2025-09-13', 1, 15000.00);
INSERT INTO public.service_usage VALUES (1498, 747, 4, '2025-09-13', 1, 1800.00);
INSERT INTO public.service_usage VALUES (1499, 747, 7, '2025-09-13', 4, 12000.00);
INSERT INTO public.service_usage VALUES (1500, 748, 1, '2025-09-17', 4, 2500.00);
INSERT INTO public.service_usage VALUES (1501, 748, 2, '2025-09-17', 2, 6000.00);
INSERT INTO public.service_usage VALUES (1502, 748, 4, '2025-09-18', 4, 1800.00);
INSERT INTO public.service_usage VALUES (1503, 749, 7, '2025-09-22', 4, 12000.00);
INSERT INTO public.service_usage VALUES (1504, 750, 2, '2025-09-29', 3, 6000.00);
INSERT INTO public.service_usage VALUES (1505, 750, 3, '2025-09-26', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1506, 750, 4, '2025-09-25', 3, 1800.00);
INSERT INTO public.service_usage VALUES (1507, 751, 6, '2025-09-30', 2, 600.00);
INSERT INTO public.service_usage VALUES (1508, 752, 1, '2025-07-02', 1, 2500.00);
INSERT INTO public.service_usage VALUES (1509, 752, 3, '2025-07-03', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1510, 752, 1, '2025-07-03', 4, 2500.00);
INSERT INTO public.service_usage VALUES (1511, 753, 6, '2025-07-06', 3, 600.00);
INSERT INTO public.service_usage VALUES (1512, 755, 6, '2025-07-18', 4, 600.00);
INSERT INTO public.service_usage VALUES (1513, 755, 3, '2025-07-19', 4, 3500.00);
INSERT INTO public.service_usage VALUES (1514, 755, 4, '2025-07-21', 4, 1800.00);
INSERT INTO public.service_usage VALUES (1515, 756, 4, '2025-07-27', 3, 1800.00);
INSERT INTO public.service_usage VALUES (1516, 756, 6, '2025-07-27', 1, 600.00);
INSERT INTO public.service_usage VALUES (1517, 756, 7, '2025-07-27', 2, 12000.00);
INSERT INTO public.service_usage VALUES (1518, 757, 3, '2025-07-31', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1519, 757, 6, '2025-07-31', 1, 600.00);
INSERT INTO public.service_usage VALUES (1520, 757, 7, '2025-08-01', 3, 12000.00);
INSERT INTO public.service_usage VALUES (1521, 759, 2, '2025-08-10', 4, 6000.00);
INSERT INTO public.service_usage VALUES (1522, 759, 2, '2025-08-08', 1, 6000.00);
INSERT INTO public.service_usage VALUES (1523, 759, 5, '2025-08-12', 1, 15000.00);
INSERT INTO public.service_usage VALUES (1524, 760, 3, '2025-08-15', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1525, 761, 6, '2025-08-20', 1, 600.00);
INSERT INTO public.service_usage VALUES (1526, 761, 7, '2025-08-20', 2, 12000.00);
INSERT INTO public.service_usage VALUES (1527, 761, 6, '2025-08-21', 4, 600.00);
INSERT INTO public.service_usage VALUES (1528, 761, 6, '2025-08-21', 4, 600.00);
INSERT INTO public.service_usage VALUES (1529, 762, 7, '2025-08-25', 2, 12000.00);
INSERT INTO public.service_usage VALUES (1530, 762, 7, '2025-08-27', 3, 12000.00);
INSERT INTO public.service_usage VALUES (1531, 762, 2, '2025-08-25', 2, 6000.00);
INSERT INTO public.service_usage VALUES (1532, 763, 6, '2025-08-30', 2, 600.00);
INSERT INTO public.service_usage VALUES (1533, 763, 6, '2025-08-30', 3, 600.00);
INSERT INTO public.service_usage VALUES (1534, 764, 6, '2025-09-03', 2, 600.00);
INSERT INTO public.service_usage VALUES (1535, 764, 5, '2025-09-02', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1536, 765, 4, '2025-09-05', 1, 1800.00);
INSERT INTO public.service_usage VALUES (1537, 765, 7, '2025-09-05', 3, 12000.00);
INSERT INTO public.service_usage VALUES (1538, 766, 6, '2025-09-07', 2, 600.00);
INSERT INTO public.service_usage VALUES (1539, 767, 1, '2025-09-10', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1540, 768, 1, '2025-09-15', 3, 2500.00);
INSERT INTO public.service_usage VALUES (1541, 768, 7, '2025-09-15', 1, 12000.00);
INSERT INTO public.service_usage VALUES (1542, 768, 6, '2025-09-15', 4, 600.00);
INSERT INTO public.service_usage VALUES (1543, 769, 6, '2025-09-18', 1, 600.00);
INSERT INTO public.service_usage VALUES (1544, 769, 1, '2025-09-17', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1545, 769, 7, '2025-09-18', 3, 12000.00);
INSERT INTO public.service_usage VALUES (1546, 769, 2, '2025-09-18', 4, 6000.00);
INSERT INTO public.service_usage VALUES (1547, 770, 4, '2025-09-24', 3, 1800.00);
INSERT INTO public.service_usage VALUES (1548, 770, 6, '2025-09-25', 3, 600.00);
INSERT INTO public.service_usage VALUES (1549, 771, 4, '2025-09-28', 4, 1800.00);
INSERT INTO public.service_usage VALUES (1550, 771, 6, '2025-09-28', 3, 600.00);
INSERT INTO public.service_usage VALUES (1551, 771, 1, '2025-09-27', 1, 2500.00);
INSERT INTO public.service_usage VALUES (1552, 776, 4, '2025-07-09', 3, 1800.00);
INSERT INTO public.service_usage VALUES (1553, 776, 7, '2025-07-10', 4, 12000.00);
INSERT INTO public.service_usage VALUES (1554, 776, 2, '2025-07-10', 2, 6000.00);
INSERT INTO public.service_usage VALUES (1555, 777, 3, '2025-07-12', 4, 3500.00);
INSERT INTO public.service_usage VALUES (1556, 778, 7, '2025-07-13', 1, 12000.00);
INSERT INTO public.service_usage VALUES (1557, 779, 1, '2025-07-15', 1, 2500.00);
INSERT INTO public.service_usage VALUES (1558, 780, 5, '2025-07-17', 4, 15000.00);
INSERT INTO public.service_usage VALUES (1559, 780, 3, '2025-07-17', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1560, 780, 7, '2025-07-16', 2, 12000.00);
INSERT INTO public.service_usage VALUES (1561, 781, 6, '2025-07-21', 1, 600.00);
INSERT INTO public.service_usage VALUES (1562, 781, 5, '2025-07-20', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1563, 781, 4, '2025-07-20', 1, 1800.00);
INSERT INTO public.service_usage VALUES (1564, 782, 1, '2025-07-23', 3, 2500.00);
INSERT INTO public.service_usage VALUES (1565, 782, 2, '2025-07-24', 1, 6000.00);
INSERT INTO public.service_usage VALUES (1566, 783, 5, '2025-07-27', 1, 15000.00);
INSERT INTO public.service_usage VALUES (1567, 783, 4, '2025-07-29', 2, 1800.00);
INSERT INTO public.service_usage VALUES (1568, 784, 6, '2025-08-02', 4, 600.00);
INSERT INTO public.service_usage VALUES (1569, 784, 6, '2025-08-02', 3, 600.00);
INSERT INTO public.service_usage VALUES (1570, 785, 6, '2025-08-04', 1, 600.00);
INSERT INTO public.service_usage VALUES (1571, 785, 5, '2025-08-04', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1572, 785, 7, '2025-08-04', 2, 12000.00);
INSERT INTO public.service_usage VALUES (1573, 785, 7, '2025-08-04', 2, 12000.00);
INSERT INTO public.service_usage VALUES (1574, 786, 2, '2025-08-07', 4, 6000.00);
INSERT INTO public.service_usage VALUES (1575, 786, 7, '2025-08-07', 2, 12000.00);
INSERT INTO public.service_usage VALUES (1576, 786, 4, '2025-08-08', 2, 1800.00);
INSERT INTO public.service_usage VALUES (1577, 786, 2, '2025-08-07', 2, 6000.00);
INSERT INTO public.service_usage VALUES (1578, 788, 7, '2025-08-12', 4, 12000.00);
INSERT INTO public.service_usage VALUES (1579, 788, 4, '2025-08-13', 4, 1800.00);
INSERT INTO public.service_usage VALUES (1580, 788, 1, '2025-08-12', 4, 2500.00);
INSERT INTO public.service_usage VALUES (1581, 788, 7, '2025-08-12', 2, 12000.00);
INSERT INTO public.service_usage VALUES (1582, 789, 4, '2025-08-16', 3, 1800.00);
INSERT INTO public.service_usage VALUES (1583, 789, 1, '2025-08-15', 3, 2500.00);
INSERT INTO public.service_usage VALUES (1584, 789, 6, '2025-08-16', 4, 600.00);
INSERT INTO public.service_usage VALUES (1585, 790, 1, '2025-08-18', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1586, 790, 7, '2025-08-18', 3, 12000.00);
INSERT INTO public.service_usage VALUES (1587, 790, 7, '2025-08-17', 2, 12000.00);
INSERT INTO public.service_usage VALUES (1588, 791, 6, '2025-08-22', 4, 600.00);
INSERT INTO public.service_usage VALUES (1589, 791, 3, '2025-08-21', 1, 3500.00);
INSERT INTO public.service_usage VALUES (1590, 791, 7, '2025-08-20', 4, 12000.00);
INSERT INTO public.service_usage VALUES (1591, 792, 7, '2025-08-28', 2, 12000.00);
INSERT INTO public.service_usage VALUES (1592, 792, 2, '2025-08-25', 1, 6000.00);
INSERT INTO public.service_usage VALUES (1593, 793, 4, '2025-09-01', 3, 1800.00);
INSERT INTO public.service_usage VALUES (1594, 794, 4, '2025-09-08', 1, 1800.00);
INSERT INTO public.service_usage VALUES (1595, 794, 6, '2025-09-08', 2, 600.00);
INSERT INTO public.service_usage VALUES (1596, 795, 3, '2025-09-10', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1597, 797, 3, '2025-09-18', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1598, 797, 7, '2025-09-19', 2, 12000.00);
INSERT INTO public.service_usage VALUES (1599, 798, 7, '2025-09-24', 4, 12000.00);
INSERT INTO public.service_usage VALUES (1600, 798, 7, '2025-09-22', 3, 12000.00);
INSERT INTO public.service_usage VALUES (1601, 799, 6, '2025-09-26', 4, 600.00);
INSERT INTO public.service_usage VALUES (1602, 800, 4, '2025-09-30', 2, 1800.00);
INSERT INTO public.service_usage VALUES (1603, 801, 1, '2025-07-03', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1604, 801, 3, '2025-07-03', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1605, 801, 3, '2025-07-02', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1606, 803, 7, '2025-07-09', 2, 12000.00);
INSERT INTO public.service_usage VALUES (1607, 803, 5, '2025-07-09', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1608, 804, 3, '2025-07-13', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1609, 804, 7, '2025-07-12', 2, 12000.00);
INSERT INTO public.service_usage VALUES (1610, 806, 3, '2025-07-22', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1611, 807, 1, '2025-07-25', 1, 2500.00);
INSERT INTO public.service_usage VALUES (1612, 807, 5, '2025-07-25', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1613, 808, 7, '2025-07-28', 1, 12000.00);
INSERT INTO public.service_usage VALUES (1614, 808, 7, '2025-07-28', 1, 12000.00);
INSERT INTO public.service_usage VALUES (1615, 808, 7, '2025-07-27', 3, 12000.00);
INSERT INTO public.service_usage VALUES (1616, 809, 2, '2025-07-31', 2, 6000.00);
INSERT INTO public.service_usage VALUES (1617, 809, 7, '2025-07-31', 4, 12000.00);
INSERT INTO public.service_usage VALUES (1618, 810, 4, '2025-08-04', 1, 1800.00);
INSERT INTO public.service_usage VALUES (1619, 810, 7, '2025-08-03', 1, 12000.00);
INSERT INTO public.service_usage VALUES (1620, 811, 6, '2025-08-06', 3, 600.00);
INSERT INTO public.service_usage VALUES (1621, 811, 1, '2025-08-06', 1, 2500.00);
INSERT INTO public.service_usage VALUES (1622, 811, 7, '2025-08-06', 4, 12000.00);
INSERT INTO public.service_usage VALUES (1623, 812, 7, '2025-08-11', 4, 12000.00);
INSERT INTO public.service_usage VALUES (1624, 812, 2, '2025-08-10', 1, 6000.00);
INSERT INTO public.service_usage VALUES (1625, 813, 7, '2025-08-12', 2, 12000.00);
INSERT INTO public.service_usage VALUES (1626, 813, 2, '2025-08-13', 3, 6000.00);
INSERT INTO public.service_usage VALUES (1627, 813, 2, '2025-08-13', 2, 6000.00);
INSERT INTO public.service_usage VALUES (1628, 814, 5, '2025-08-19', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1629, 814, 6, '2025-08-19', 4, 600.00);
INSERT INTO public.service_usage VALUES (1630, 815, 6, '2025-08-21', 4, 600.00);
INSERT INTO public.service_usage VALUES (1631, 815, 7, '2025-08-21', 2, 12000.00);
INSERT INTO public.service_usage VALUES (1632, 816, 4, '2025-08-25', 4, 1800.00);
INSERT INTO public.service_usage VALUES (1633, 816, 2, '2025-08-25', 2, 6000.00);
INSERT INTO public.service_usage VALUES (1634, 816, 3, '2025-08-25', 1, 3500.00);
INSERT INTO public.service_usage VALUES (1635, 816, 3, '2025-08-25', 4, 3500.00);
INSERT INTO public.service_usage VALUES (1636, 817, 1, '2025-08-30', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1637, 817, 6, '2025-08-27', 3, 600.00);
INSERT INTO public.service_usage VALUES (1638, 817, 3, '2025-08-30', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1639, 818, 3, '2025-09-03', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1640, 818, 3, '2025-09-02', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1641, 819, 6, '2025-09-08', 3, 600.00);
INSERT INTO public.service_usage VALUES (1642, 819, 6, '2025-09-07', 3, 600.00);
INSERT INTO public.service_usage VALUES (1643, 820, 6, '2025-09-12', 4, 600.00);
INSERT INTO public.service_usage VALUES (1644, 820, 2, '2025-09-12', 3, 6000.00);
INSERT INTO public.service_usage VALUES (1645, 820, 6, '2025-09-11', 3, 600.00);
INSERT INTO public.service_usage VALUES (1646, 821, 3, '2025-09-16', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1647, 821, 3, '2025-09-16', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1648, 821, 5, '2025-09-15', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1649, 822, 2, '2025-09-24', 2, 6000.00);
INSERT INTO public.service_usage VALUES (1650, 822, 2, '2025-09-24', 4, 6000.00);
INSERT INTO public.service_usage VALUES (1651, 822, 2, '2025-09-22', 2, 6000.00);
INSERT INTO public.service_usage VALUES (1652, 822, 4, '2025-09-22', 1, 1800.00);
INSERT INTO public.service_usage VALUES (1653, 823, 7, '2025-09-25', 2, 12000.00);
INSERT INTO public.service_usage VALUES (1654, 823, 1, '2025-09-25', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1655, 824, 3, '2025-09-27', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1656, 825, 1, '2025-09-28', 1, 2500.00);
INSERT INTO public.service_usage VALUES (1657, 825, 7, '2025-09-28', 2, 12000.00);
INSERT INTO public.service_usage VALUES (1658, 825, 1, '2025-09-28', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1659, 825, 2, '2025-09-28', 3, 6000.00);
INSERT INTO public.service_usage VALUES (1660, 826, 3, '2025-09-30', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1661, 826, 3, '2025-10-01', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1662, 827, 5, '2025-07-02', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1663, 827, 2, '2025-07-01', 3, 6000.00);
INSERT INTO public.service_usage VALUES (1664, 828, 5, '2025-07-05', 4, 15000.00);
INSERT INTO public.service_usage VALUES (1665, 828, 1, '2025-07-05', 3, 2500.00);
INSERT INTO public.service_usage VALUES (1666, 828, 6, '2025-07-06', 4, 600.00);
INSERT INTO public.service_usage VALUES (1667, 830, 7, '2025-07-11', 3, 12000.00);
INSERT INTO public.service_usage VALUES (1668, 830, 6, '2025-07-11', 1, 600.00);
INSERT INTO public.service_usage VALUES (1669, 830, 6, '2025-07-12', 2, 600.00);
INSERT INTO public.service_usage VALUES (1670, 831, 7, '2025-07-15', 1, 12000.00);
INSERT INTO public.service_usage VALUES (1671, 831, 2, '2025-07-15', 1, 6000.00);
INSERT INTO public.service_usage VALUES (1672, 831, 6, '2025-07-15', 2, 600.00);
INSERT INTO public.service_usage VALUES (1673, 832, 7, '2025-07-17', 4, 12000.00);
INSERT INTO public.service_usage VALUES (1674, 832, 3, '2025-07-17', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1675, 832, 4, '2025-07-19', 3, 1800.00);
INSERT INTO public.service_usage VALUES (1676, 833, 6, '2025-07-22', 3, 600.00);
INSERT INTO public.service_usage VALUES (1677, 834, 3, '2025-07-25', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1678, 834, 6, '2025-07-25', 2, 600.00);
INSERT INTO public.service_usage VALUES (1679, 834, 6, '2025-07-25', 1, 600.00);
INSERT INTO public.service_usage VALUES (1680, 835, 6, '2025-07-27', 3, 600.00);
INSERT INTO public.service_usage VALUES (1681, 835, 5, '2025-07-27', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1682, 835, 7, '2025-07-27', 2, 12000.00);
INSERT INTO public.service_usage VALUES (1683, 836, 2, '2025-07-30', 2, 6000.00);
INSERT INTO public.service_usage VALUES (1684, 836, 6, '2025-07-29', 1, 600.00);
INSERT INTO public.service_usage VALUES (1685, 836, 7, '2025-07-30', 2, 12000.00);
INSERT INTO public.service_usage VALUES (1686, 837, 6, '2025-08-05', 3, 600.00);
INSERT INTO public.service_usage VALUES (1687, 837, 3, '2025-08-02', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1688, 838, 7, '2025-08-07', 1, 12000.00);
INSERT INTO public.service_usage VALUES (1689, 838, 7, '2025-08-07', 4, 12000.00);
INSERT INTO public.service_usage VALUES (1690, 838, 5, '2025-08-07', 1, 15000.00);
INSERT INTO public.service_usage VALUES (1691, 839, 3, '2025-08-10', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1692, 839, 3, '2025-08-10', 1, 3500.00);
INSERT INTO public.service_usage VALUES (1693, 839, 7, '2025-08-11', 2, 12000.00);
INSERT INTO public.service_usage VALUES (1694, 839, 5, '2025-08-11', 1, 15000.00);
INSERT INTO public.service_usage VALUES (1695, 840, 1, '2025-08-14', 4, 2500.00);
INSERT INTO public.service_usage VALUES (1696, 841, 7, '2025-08-18', 3, 12000.00);
INSERT INTO public.service_usage VALUES (1697, 842, 3, '2025-08-22', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1698, 843, 7, '2025-08-30', 3, 12000.00);
INSERT INTO public.service_usage VALUES (1699, 843, 1, '2025-08-30', 3, 2500.00);
INSERT INTO public.service_usage VALUES (1700, 844, 6, '2025-09-02', 1, 600.00);
INSERT INTO public.service_usage VALUES (1701, 845, 6, '2025-09-06', 2, 600.00);
INSERT INTO public.service_usage VALUES (1702, 845, 1, '2025-09-08', 1, 2500.00);
INSERT INTO public.service_usage VALUES (1703, 846, 3, '2025-09-13', 4, 3500.00);
INSERT INTO public.service_usage VALUES (1704, 846, 2, '2025-09-12', 3, 6000.00);
INSERT INTO public.service_usage VALUES (1705, 846, 5, '2025-09-12', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1706, 847, 1, '2025-09-16', 3, 2500.00);
INSERT INTO public.service_usage VALUES (1707, 848, 4, '2025-09-20', 2, 1800.00);
INSERT INTO public.service_usage VALUES (1708, 848, 1, '2025-09-20', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1709, 848, 1, '2025-09-21', 4, 2500.00);
INSERT INTO public.service_usage VALUES (1710, 848, 7, '2025-09-21', 3, 12000.00);
INSERT INTO public.service_usage VALUES (1711, 849, 5, '2025-09-24', 1, 15000.00);
INSERT INTO public.service_usage VALUES (1712, 849, 7, '2025-09-24', 1, 12000.00);
INSERT INTO public.service_usage VALUES (1713, 849, 4, '2025-09-24', 2, 1800.00);
INSERT INTO public.service_usage VALUES (1714, 850, 5, '2025-09-27', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1715, 851, 2, '2025-09-30', 4, 6000.00);
INSERT INTO public.service_usage VALUES (1716, 851, 6, '2025-10-01', 2, 600.00);
INSERT INTO public.service_usage VALUES (1717, 852, 5, '2025-07-02', 1, 15000.00);
INSERT INTO public.service_usage VALUES (1718, 852, 1, '2025-07-02', 3, 2500.00);
INSERT INTO public.service_usage VALUES (1719, 853, 2, '2025-07-06', 2, 6000.00);
INSERT INTO public.service_usage VALUES (1720, 853, 7, '2025-07-06', 4, 12000.00);
INSERT INTO public.service_usage VALUES (1721, 854, 5, '2025-07-09', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1722, 855, 3, '2025-07-14', 4, 3500.00);
INSERT INTO public.service_usage VALUES (1723, 856, 2, '2025-07-16', 2, 6000.00);
INSERT INTO public.service_usage VALUES (1724, 857, 6, '2025-07-22', 3, 600.00);
INSERT INTO public.service_usage VALUES (1725, 857, 2, '2025-07-22', 4, 6000.00);
INSERT INTO public.service_usage VALUES (1726, 857, 3, '2025-07-21', 1, 3500.00);
INSERT INTO public.service_usage VALUES (1727, 858, 4, '2025-07-28', 3, 1800.00);
INSERT INTO public.service_usage VALUES (1728, 858, 3, '2025-07-27', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1729, 858, 7, '2025-07-28', 2, 12000.00);
INSERT INTO public.service_usage VALUES (1730, 859, 3, '2025-07-30', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1731, 859, 2, '2025-07-30', 2, 6000.00);
INSERT INTO public.service_usage VALUES (1732, 859, 3, '2025-07-30', 4, 3500.00);
INSERT INTO public.service_usage VALUES (1733, 859, 5, '2025-08-02', 4, 15000.00);
INSERT INTO public.service_usage VALUES (1734, 861, 7, '2025-08-09', 3, 12000.00);
INSERT INTO public.service_usage VALUES (1735, 861, 7, '2025-08-12', 3, 12000.00);
INSERT INTO public.service_usage VALUES (1736, 861, 1, '2025-08-12', 1, 2500.00);
INSERT INTO public.service_usage VALUES (1737, 862, 3, '2025-08-15', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1738, 862, 1, '2025-08-14', 3, 2500.00);
INSERT INTO public.service_usage VALUES (1739, 863, 6, '2025-08-18', 2, 600.00);
INSERT INTO public.service_usage VALUES (1740, 863, 7, '2025-08-17', 2, 12000.00);
INSERT INTO public.service_usage VALUES (1741, 864, 3, '2025-08-22', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1742, 864, 2, '2025-08-21', 1, 6000.00);
INSERT INTO public.service_usage VALUES (1743, 864, 6, '2025-08-22', 3, 600.00);
INSERT INTO public.service_usage VALUES (1744, 864, 5, '2025-08-22', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1745, 865, 6, '2025-08-24', 3, 600.00);
INSERT INTO public.service_usage VALUES (1746, 866, 3, '2025-08-27', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1747, 866, 6, '2025-08-30', 4, 600.00);
INSERT INTO public.service_usage VALUES (1748, 866, 5, '2025-08-30', 1, 15000.00);
INSERT INTO public.service_usage VALUES (1749, 868, 1, '2025-09-05', 3, 2500.00);
INSERT INTO public.service_usage VALUES (1750, 868, 4, '2025-09-05', 3, 1800.00);
INSERT INTO public.service_usage VALUES (1751, 869, 7, '2025-09-08', 3, 12000.00);
INSERT INTO public.service_usage VALUES (1752, 869, 5, '2025-09-09', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1753, 869, 3, '2025-09-09', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1754, 870, 5, '2025-09-11', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1755, 870, 3, '2025-09-12', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1756, 870, 7, '2025-09-11', 1, 12000.00);
INSERT INTO public.service_usage VALUES (1757, 871, 2, '2025-09-17', 3, 6000.00);
INSERT INTO public.service_usage VALUES (1758, 872, 5, '2025-09-19', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1759, 872, 5, '2025-09-20', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1760, 873, 4, '2025-09-22', 2, 1800.00);
INSERT INTO public.service_usage VALUES (1761, 873, 2, '2025-09-23', 3, 6000.00);
INSERT INTO public.service_usage VALUES (1762, 873, 7, '2025-09-22', 2, 12000.00);
INSERT INTO public.service_usage VALUES (1763, 873, 3, '2025-09-23', 1, 3500.00);
INSERT INTO public.service_usage VALUES (1764, 874, 6, '2025-09-26', 1, 600.00);
INSERT INTO public.service_usage VALUES (1765, 874, 6, '2025-09-25', 4, 600.00);
INSERT INTO public.service_usage VALUES (1766, 874, 1, '2025-09-25', 3, 2500.00);
INSERT INTO public.service_usage VALUES (1767, 874, 4, '2025-09-26', 2, 1800.00);
INSERT INTO public.service_usage VALUES (1768, 875, 4, '2025-09-30', 2, 1800.00);
INSERT INTO public.service_usage VALUES (1769, 875, 4, '2025-10-01', 2, 1800.00);
INSERT INTO public.service_usage VALUES (1770, 876, 7, '2025-07-03', 4, 12000.00);
INSERT INTO public.service_usage VALUES (1771, 876, 1, '2025-07-02', 1, 2500.00);
INSERT INTO public.service_usage VALUES (1772, 876, 7, '2025-07-01', 1, 12000.00);
INSERT INTO public.service_usage VALUES (1773, 877, 7, '2025-07-05', 3, 12000.00);
INSERT INTO public.service_usage VALUES (1774, 877, 4, '2025-07-06', 2, 1800.00);
INSERT INTO public.service_usage VALUES (1775, 877, 2, '2025-07-06', 3, 6000.00);
INSERT INTO public.service_usage VALUES (1776, 878, 6, '2025-07-11', 3, 600.00);
INSERT INTO public.service_usage VALUES (1777, 878, 5, '2025-07-09', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1778, 878, 7, '2025-07-12', 4, 12000.00);
INSERT INTO public.service_usage VALUES (1779, 878, 6, '2025-07-10', 1, 600.00);
INSERT INTO public.service_usage VALUES (1780, 879, 3, '2025-07-14', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1781, 879, 5, '2025-07-14', 4, 15000.00);
INSERT INTO public.service_usage VALUES (1782, 880, 3, '2025-07-18', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1783, 880, 5, '2025-07-18', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1784, 880, 5, '2025-07-19', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1785, 881, 1, '2025-07-24', 4, 2500.00);
INSERT INTO public.service_usage VALUES (1786, 881, 5, '2025-07-24', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1787, 881, 3, '2025-07-23', 4, 3500.00);
INSERT INTO public.service_usage VALUES (1788, 882, 5, '2025-07-27', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1789, 883, 7, '2025-07-30', 3, 12000.00);
INSERT INTO public.service_usage VALUES (1790, 883, 7, '2025-07-30', 4, 12000.00);
INSERT INTO public.service_usage VALUES (1791, 883, 4, '2025-07-30', 3, 1800.00);
INSERT INTO public.service_usage VALUES (1792, 885, 5, '2025-08-04', 4, 15000.00);
INSERT INTO public.service_usage VALUES (1793, 886, 5, '2025-08-06', 1, 15000.00);
INSERT INTO public.service_usage VALUES (1794, 886, 3, '2025-08-05', 4, 3500.00);
INSERT INTO public.service_usage VALUES (1795, 887, 6, '2025-08-09', 3, 600.00);
INSERT INTO public.service_usage VALUES (1796, 887, 3, '2025-08-08', 4, 3500.00);
INSERT INTO public.service_usage VALUES (1797, 887, 5, '2025-08-10', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1798, 887, 5, '2025-08-10', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1799, 888, 1, '2025-08-13', 1, 2500.00);
INSERT INTO public.service_usage VALUES (1800, 888, 3, '2025-08-13', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1801, 888, 2, '2025-08-14', 2, 6000.00);
INSERT INTO public.service_usage VALUES (1802, 888, 5, '2025-08-14', 1, 15000.00);
INSERT INTO public.service_usage VALUES (1803, 889, 7, '2025-08-16', 2, 12000.00);
INSERT INTO public.service_usage VALUES (1804, 889, 3, '2025-08-16', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1805, 889, 5, '2025-08-16', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1806, 889, 2, '2025-08-16', 4, 6000.00);
INSERT INTO public.service_usage VALUES (1807, 890, 1, '2025-08-20', 3, 2500.00);
INSERT INTO public.service_usage VALUES (1808, 890, 2, '2025-08-19', 3, 6000.00);
INSERT INTO public.service_usage VALUES (1809, 890, 2, '2025-08-20', 2, 6000.00);
INSERT INTO public.service_usage VALUES (1810, 890, 3, '2025-08-19', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1811, 891, 5, '2025-08-22', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1812, 891, 6, '2025-08-23', 2, 600.00);
INSERT INTO public.service_usage VALUES (1813, 891, 7, '2025-08-23', 4, 12000.00);
INSERT INTO public.service_usage VALUES (1814, 892, 4, '2025-08-28', 2, 1800.00);
INSERT INTO public.service_usage VALUES (1815, 892, 3, '2025-08-24', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1816, 893, 2, '2025-09-01', 1, 6000.00);
INSERT INTO public.service_usage VALUES (1817, 893, 5, '2025-08-31', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1818, 893, 4, '2025-08-31', 1, 1800.00);
INSERT INTO public.service_usage VALUES (1819, 893, 3, '2025-09-01', 1, 3500.00);
INSERT INTO public.service_usage VALUES (1820, 894, 1, '2025-09-05', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1821, 894, 3, '2025-09-06', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1822, 894, 1, '2025-09-05', 4, 2500.00);
INSERT INTO public.service_usage VALUES (1823, 894, 7, '2025-09-06', 3, 12000.00);
INSERT INTO public.service_usage VALUES (1824, 895, 3, '2025-09-09', 4, 3500.00);
INSERT INTO public.service_usage VALUES (1825, 895, 7, '2025-09-10', 3, 12000.00);
INSERT INTO public.service_usage VALUES (1826, 897, 1, '2025-09-18', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1827, 897, 2, '2025-09-19', 2, 6000.00);
INSERT INTO public.service_usage VALUES (1828, 898, 6, '2025-09-21', 2, 600.00);
INSERT INTO public.service_usage VALUES (1829, 898, 1, '2025-09-22', 4, 2500.00);
INSERT INTO public.service_usage VALUES (1830, 898, 2, '2025-09-22', 2, 6000.00);
INSERT INTO public.service_usage VALUES (1831, 898, 2, '2025-09-22', 4, 6000.00);
INSERT INTO public.service_usage VALUES (1832, 899, 4, '2025-09-25', 3, 1800.00);
INSERT INTO public.service_usage VALUES (1833, 899, 5, '2025-09-26', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1834, 899, 1, '2025-09-25', 1, 2500.00);
INSERT INTO public.service_usage VALUES (1835, 900, 5, '2025-09-29', 1, 15000.00);
INSERT INTO public.service_usage VALUES (1836, 900, 3, '2025-09-30', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1837, 900, 6, '2025-09-29', 4, 600.00);
INSERT INTO public.service_usage VALUES (1838, 902, 2, '2025-07-09', 3, 6000.00);
INSERT INTO public.service_usage VALUES (1839, 902, 4, '2025-07-09', 3, 1800.00);
INSERT INTO public.service_usage VALUES (1840, 903, 7, '2025-07-12', 2, 12000.00);
INSERT INTO public.service_usage VALUES (1841, 903, 3, '2025-07-13', 4, 3500.00);
INSERT INTO public.service_usage VALUES (1842, 904, 4, '2025-07-16', 4, 1800.00);
INSERT INTO public.service_usage VALUES (1843, 905, 1, '2025-07-19', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1844, 906, 6, '2025-07-21', 4, 600.00);
INSERT INTO public.service_usage VALUES (1845, 906, 1, '2025-07-24', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1846, 906, 6, '2025-07-23', 3, 600.00);
INSERT INTO public.service_usage VALUES (1847, 907, 5, '2025-07-26', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1848, 907, 5, '2025-07-29', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1849, 908, 6, '2025-08-02', 1, 600.00);
INSERT INTO public.service_usage VALUES (1850, 908, 6, '2025-08-02', 4, 600.00);
INSERT INTO public.service_usage VALUES (1851, 910, 4, '2025-08-09', 1, 1800.00);
INSERT INTO public.service_usage VALUES (1852, 910, 1, '2025-08-09', 4, 2500.00);
INSERT INTO public.service_usage VALUES (1853, 910, 1, '2025-08-09', 3, 2500.00);
INSERT INTO public.service_usage VALUES (1854, 910, 5, '2025-08-09', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1855, 911, 1, '2025-08-13', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1856, 911, 1, '2025-08-12', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1857, 912, 3, '2025-08-18', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1858, 912, 1, '2025-08-19', 1, 2500.00);
INSERT INTO public.service_usage VALUES (1859, 913, 3, '2025-08-21', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1860, 914, 1, '2025-08-29', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1861, 914, 6, '2025-08-26', 2, 600.00);
INSERT INTO public.service_usage VALUES (1862, 915, 2, '2025-09-02', 1, 6000.00);
INSERT INTO public.service_usage VALUES (1863, 915, 2, '2025-09-01', 2, 6000.00);
INSERT INTO public.service_usage VALUES (1864, 915, 3, '2025-09-03', 1, 3500.00);
INSERT INTO public.service_usage VALUES (1865, 916, 1, '2025-09-07', 4, 2500.00);
INSERT INTO public.service_usage VALUES (1866, 916, 7, '2025-09-05', 4, 12000.00);
INSERT INTO public.service_usage VALUES (1867, 916, 7, '2025-09-05', 3, 12000.00);
INSERT INTO public.service_usage VALUES (1868, 917, 5, '2025-09-09', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1869, 917, 2, '2025-09-09', 4, 6000.00);
INSERT INTO public.service_usage VALUES (1870, 917, 5, '2025-09-09', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1871, 918, 2, '2025-09-13', 3, 6000.00);
INSERT INTO public.service_usage VALUES (1872, 919, 7, '2025-09-19', 3, 12000.00);
INSERT INTO public.service_usage VALUES (1873, 919, 6, '2025-09-18', 3, 600.00);
INSERT INTO public.service_usage VALUES (1874, 920, 6, '2025-09-22', 4, 600.00);
INSERT INTO public.service_usage VALUES (1875, 920, 5, '2025-09-24', 4, 15000.00);
INSERT INTO public.service_usage VALUES (1876, 921, 7, '2025-09-27', 3, 12000.00);
INSERT INTO public.service_usage VALUES (1877, 921, 1, '2025-09-27', 3, 2500.00);
INSERT INTO public.service_usage VALUES (1878, 922, 5, '2025-07-01', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1879, 924, 5, '2025-07-08', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1880, 924, 2, '2025-07-07', 2, 6000.00);
INSERT INTO public.service_usage VALUES (1881, 924, 4, '2025-07-07', 1, 1800.00);
INSERT INTO public.service_usage VALUES (1882, 925, 6, '2025-07-10', 2, 600.00);
INSERT INTO public.service_usage VALUES (1883, 925, 4, '2025-07-10', 3, 1800.00);
INSERT INTO public.service_usage VALUES (1884, 925, 6, '2025-07-11', 2, 600.00);
INSERT INTO public.service_usage VALUES (1885, 926, 4, '2025-07-14', 1, 1800.00);
INSERT INTO public.service_usage VALUES (1886, 926, 5, '2025-07-13', 4, 15000.00);
INSERT INTO public.service_usage VALUES (1887, 926, 5, '2025-07-13', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1888, 926, 4, '2025-07-13', 4, 1800.00);
INSERT INTO public.service_usage VALUES (1889, 927, 5, '2025-07-17', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1890, 927, 2, '2025-07-18', 2, 6000.00);
INSERT INTO public.service_usage VALUES (1891, 927, 4, '2025-07-18', 3, 1800.00);
INSERT INTO public.service_usage VALUES (1892, 928, 2, '2025-07-24', 2, 6000.00);
INSERT INTO public.service_usage VALUES (1893, 928, 5, '2025-07-24', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1894, 928, 6, '2025-07-22', 3, 600.00);
INSERT INTO public.service_usage VALUES (1895, 929, 7, '2025-07-27', 2, 12000.00);
INSERT INTO public.service_usage VALUES (1896, 929, 2, '2025-07-27', 3, 6000.00);
INSERT INTO public.service_usage VALUES (1897, 930, 4, '2025-08-01', 2, 1800.00);
INSERT INTO public.service_usage VALUES (1898, 930, 3, '2025-07-31', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1899, 930, 7, '2025-07-31', 4, 12000.00);
INSERT INTO public.service_usage VALUES (1900, 930, 4, '2025-08-01', 2, 1800.00);
INSERT INTO public.service_usage VALUES (1901, 932, 6, '2025-08-08', 1, 600.00);
INSERT INTO public.service_usage VALUES (1902, 933, 5, '2025-08-12', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1903, 933, 1, '2025-08-12', 4, 2500.00);
INSERT INTO public.service_usage VALUES (1904, 933, 4, '2025-08-14', 1, 1800.00);
INSERT INTO public.service_usage VALUES (1905, 934, 3, '2025-08-20', 1, 3500.00);
INSERT INTO public.service_usage VALUES (1906, 934, 3, '2025-08-21', 1, 3500.00);
INSERT INTO public.service_usage VALUES (1907, 935, 1, '2025-08-23', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1908, 935, 1, '2025-08-23', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1909, 936, 2, '2025-08-27', 3, 6000.00);
INSERT INTO public.service_usage VALUES (1910, 936, 7, '2025-08-28', 1, 12000.00);
INSERT INTO public.service_usage VALUES (1911, 936, 6, '2025-08-27', 2, 600.00);
INSERT INTO public.service_usage VALUES (1912, 937, 6, '2025-09-01', 3, 600.00);
INSERT INTO public.service_usage VALUES (1913, 937, 2, '2025-08-31', 3, 6000.00);
INSERT INTO public.service_usage VALUES (1914, 937, 1, '2025-09-01', 3, 2500.00);
INSERT INTO public.service_usage VALUES (1915, 938, 5, '2025-09-05', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1916, 938, 3, '2025-09-05', 1, 3500.00);
INSERT INTO public.service_usage VALUES (1917, 938, 3, '2025-09-05', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1918, 938, 6, '2025-09-06', 1, 600.00);
INSERT INTO public.service_usage VALUES (1919, 939, 6, '2025-09-10', 2, 600.00);
INSERT INTO public.service_usage VALUES (1920, 939, 6, '2025-09-10', 3, 600.00);
INSERT INTO public.service_usage VALUES (1921, 940, 6, '2025-09-12', 2, 600.00);
INSERT INTO public.service_usage VALUES (1922, 940, 4, '2025-09-12', 2, 1800.00);
INSERT INTO public.service_usage VALUES (1923, 940, 3, '2025-09-11', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1924, 941, 2, '2025-09-15', 4, 6000.00);
INSERT INTO public.service_usage VALUES (1925, 941, 2, '2025-09-17', 2, 6000.00);
INSERT INTO public.service_usage VALUES (1926, 942, 2, '2025-09-19', 3, 6000.00);
INSERT INTO public.service_usage VALUES (1927, 942, 2, '2025-09-21', 2, 6000.00);
INSERT INTO public.service_usage VALUES (1928, 943, 2, '2025-09-27', 3, 6000.00);
INSERT INTO public.service_usage VALUES (1929, 944, 2, '2025-10-02', 1, 6000.00);
INSERT INTO public.service_usage VALUES (1930, 945, 1, '2025-07-01', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1931, 946, 2, '2025-07-09', 2, 6000.00);
INSERT INTO public.service_usage VALUES (1932, 946, 3, '2025-07-09', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1933, 946, 3, '2025-07-08', 1, 3500.00);
INSERT INTO public.service_usage VALUES (1934, 947, 6, '2025-07-13', 3, 600.00);
INSERT INTO public.service_usage VALUES (1935, 947, 5, '2025-07-13', 4, 15000.00);
INSERT INTO public.service_usage VALUES (1936, 947, 5, '2025-07-14', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1937, 947, 5, '2025-07-13', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1938, 948, 5, '2025-07-16', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1939, 949, 7, '2025-07-18', 3, 12000.00);
INSERT INTO public.service_usage VALUES (1940, 949, 3, '2025-07-17', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1941, 950, 7, '2025-07-20', 2, 12000.00);
INSERT INTO public.service_usage VALUES (1942, 950, 3, '2025-07-20', 1, 3500.00);
INSERT INTO public.service_usage VALUES (1943, 950, 1, '2025-07-19', 4, 2500.00);
INSERT INTO public.service_usage VALUES (1944, 951, 1, '2025-07-24', 3, 2500.00);
INSERT INTO public.service_usage VALUES (1945, 951, 6, '2025-07-24', 1, 600.00);
INSERT INTO public.service_usage VALUES (1946, 951, 3, '2025-07-25', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1947, 951, 3, '2025-07-24', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1948, 952, 4, '2025-07-27', 3, 1800.00);
INSERT INTO public.service_usage VALUES (1949, 953, 5, '2025-07-29', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1950, 954, 6, '2025-08-03', 2, 600.00);
INSERT INTO public.service_usage VALUES (1951, 954, 6, '2025-08-04', 2, 600.00);
INSERT INTO public.service_usage VALUES (1952, 954, 3, '2025-08-03', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1953, 955, 3, '2025-08-10', 1, 3500.00);
INSERT INTO public.service_usage VALUES (1954, 955, 3, '2025-08-11', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1955, 955, 1, '2025-08-10', 1, 2500.00);
INSERT INTO public.service_usage VALUES (1956, 956, 5, '2025-08-14', 4, 15000.00);
INSERT INTO public.service_usage VALUES (1957, 956, 5, '2025-08-13', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1958, 957, 5, '2025-08-18', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1959, 957, 4, '2025-08-17', 3, 1800.00);
INSERT INTO public.service_usage VALUES (1960, 958, 5, '2025-08-22', 3, 15000.00);
INSERT INTO public.service_usage VALUES (1961, 958, 1, '2025-08-20', 4, 2500.00);
INSERT INTO public.service_usage VALUES (1962, 958, 6, '2025-08-21', 4, 600.00);
INSERT INTO public.service_usage VALUES (1963, 959, 4, '2025-08-24', 1, 1800.00);
INSERT INTO public.service_usage VALUES (1964, 959, 6, '2025-08-24', 3, 600.00);
INSERT INTO public.service_usage VALUES (1965, 959, 1, '2025-08-25', 3, 2500.00);
INSERT INTO public.service_usage VALUES (1966, 960, 5, '2025-08-28', 1, 15000.00);
INSERT INTO public.service_usage VALUES (1967, 960, 2, '2025-08-28', 3, 6000.00);
INSERT INTO public.service_usage VALUES (1968, 961, 3, '2025-08-30', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1969, 961, 4, '2025-08-31', 3, 1800.00);
INSERT INTO public.service_usage VALUES (1970, 961, 4, '2025-09-02', 1, 1800.00);
INSERT INTO public.service_usage VALUES (1971, 961, 3, '2025-09-01', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1972, 962, 1, '2025-09-05', 1, 2500.00);
INSERT INTO public.service_usage VALUES (1973, 962, 6, '2025-09-04', 1, 600.00);
INSERT INTO public.service_usage VALUES (1974, 962, 6, '2025-09-05', 3, 600.00);
INSERT INTO public.service_usage VALUES (1975, 962, 6, '2025-09-04', 1, 600.00);
INSERT INTO public.service_usage VALUES (1976, 963, 6, '2025-09-08', 3, 600.00);
INSERT INTO public.service_usage VALUES (1977, 963, 6, '2025-09-07', 3, 600.00);
INSERT INTO public.service_usage VALUES (1978, 964, 3, '2025-09-13', 2, 3500.00);
INSERT INTO public.service_usage VALUES (1979, 964, 2, '2025-09-12', 3, 6000.00);
INSERT INTO public.service_usage VALUES (1980, 965, 4, '2025-09-16', 1, 1800.00);
INSERT INTO public.service_usage VALUES (1981, 965, 1, '2025-09-18', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1982, 965, 4, '2025-09-16', 2, 1800.00);
INSERT INTO public.service_usage VALUES (1983, 966, 1, '2025-09-24', 3, 2500.00);
INSERT INTO public.service_usage VALUES (1984, 967, 3, '2025-09-29', 4, 3500.00);
INSERT INTO public.service_usage VALUES (1985, 967, 4, '2025-09-29', 3, 1800.00);
INSERT INTO public.service_usage VALUES (1986, 967, 2, '2025-09-29', 1, 6000.00);
INSERT INTO public.service_usage VALUES (1987, 968, 1, '2025-07-01', 1, 2500.00);
INSERT INTO public.service_usage VALUES (1988, 968, 7, '2025-07-01', 3, 12000.00);
INSERT INTO public.service_usage VALUES (1989, 968, 1, '2025-07-01', 3, 2500.00);
INSERT INTO public.service_usage VALUES (1990, 968, 3, '2025-07-01', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1991, 969, 5, '2025-07-04', 1, 15000.00);
INSERT INTO public.service_usage VALUES (1992, 969, 3, '2025-07-05', 3, 3500.00);
INSERT INTO public.service_usage VALUES (1993, 969, 6, '2025-07-05', 3, 600.00);
INSERT INTO public.service_usage VALUES (1994, 970, 6, '2025-07-12', 3, 600.00);
INSERT INTO public.service_usage VALUES (1995, 970, 1, '2025-07-08', 2, 2500.00);
INSERT INTO public.service_usage VALUES (1996, 970, 4, '2025-07-09', 2, 1800.00);
INSERT INTO public.service_usage VALUES (1997, 971, 2, '2025-07-14', 2, 6000.00);
INSERT INTO public.service_usage VALUES (1998, 971, 5, '2025-07-15', 2, 15000.00);
INSERT INTO public.service_usage VALUES (1999, 972, 1, '2025-07-18', 2, 2500.00);
INSERT INTO public.service_usage VALUES (2000, 972, 4, '2025-07-19', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2001, 973, 4, '2025-07-22', 3, 1800.00);
INSERT INTO public.service_usage VALUES (2002, 973, 2, '2025-07-23', 2, 6000.00);
INSERT INTO public.service_usage VALUES (2003, 974, 2, '2025-07-26', 1, 6000.00);
INSERT INTO public.service_usage VALUES (2004, 974, 4, '2025-07-27', 3, 1800.00);
INSERT INTO public.service_usage VALUES (2005, 974, 2, '2025-07-27', 2, 6000.00);
INSERT INTO public.service_usage VALUES (2006, 974, 6, '2025-07-28', 3, 600.00);
INSERT INTO public.service_usage VALUES (2007, 975, 2, '2025-08-01', 4, 6000.00);
INSERT INTO public.service_usage VALUES (2008, 975, 2, '2025-07-31', 2, 6000.00);
INSERT INTO public.service_usage VALUES (2009, 975, 6, '2025-07-31', 3, 600.00);
INSERT INTO public.service_usage VALUES (2010, 975, 1, '2025-08-02', 1, 2500.00);
INSERT INTO public.service_usage VALUES (2011, 976, 6, '2025-08-08', 3, 600.00);
INSERT INTO public.service_usage VALUES (2012, 976, 6, '2025-08-07', 3, 600.00);
INSERT INTO public.service_usage VALUES (2013, 976, 7, '2025-08-07', 4, 12000.00);
INSERT INTO public.service_usage VALUES (2014, 976, 1, '2025-08-07', 2, 2500.00);
INSERT INTO public.service_usage VALUES (2015, 977, 4, '2025-08-12', 4, 1800.00);
INSERT INTO public.service_usage VALUES (2016, 977, 2, '2025-08-12', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2017, 979, 7, '2025-08-16', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2018, 979, 5, '2025-08-17', 1, 15000.00);
INSERT INTO public.service_usage VALUES (2019, 979, 5, '2025-08-17', 1, 15000.00);
INSERT INTO public.service_usage VALUES (2020, 980, 5, '2025-08-21', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2021, 980, 2, '2025-08-22', 2, 6000.00);
INSERT INTO public.service_usage VALUES (2022, 981, 6, '2025-08-29', 2, 600.00);
INSERT INTO public.service_usage VALUES (2023, 981, 7, '2025-08-28', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2024, 981, 4, '2025-08-28', 4, 1800.00);
INSERT INTO public.service_usage VALUES (2025, 982, 5, '2025-08-31', 1, 15000.00);
INSERT INTO public.service_usage VALUES (2026, 982, 4, '2025-08-31', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2027, 983, 7, '2025-09-03', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2028, 983, 6, '2025-09-06', 3, 600.00);
INSERT INTO public.service_usage VALUES (2029, 983, 4, '2025-09-05', 3, 1800.00);
INSERT INTO public.service_usage VALUES (2030, 985, 6, '2025-09-17', 2, 600.00);
INSERT INTO public.service_usage VALUES (2031, 985, 2, '2025-09-17', 1, 6000.00);
INSERT INTO public.service_usage VALUES (2032, 985, 2, '2025-09-19', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2033, 989, 6, '2025-07-04', 4, 600.00);
INSERT INTO public.service_usage VALUES (2034, 991, 4, '2025-07-09', 4, 1800.00);
INSERT INTO public.service_usage VALUES (2035, 991, 5, '2025-07-09', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2036, 991, 5, '2025-07-09', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2037, 992, 2, '2025-07-11', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2038, 993, 4, '2025-07-15', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2039, 993, 7, '2025-07-16', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2040, 994, 1, '2025-07-19', 2, 2500.00);
INSERT INTO public.service_usage VALUES (2041, 994, 1, '2025-07-19', 2, 2500.00);
INSERT INTO public.service_usage VALUES (2042, 994, 7, '2025-07-20', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2043, 995, 2, '2025-07-24', 2, 6000.00);
INSERT INTO public.service_usage VALUES (2044, 995, 5, '2025-07-24', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2045, 996, 3, '2025-07-28', 2, 3500.00);
INSERT INTO public.service_usage VALUES (2046, 998, 6, '2025-08-05', 4, 600.00);
INSERT INTO public.service_usage VALUES (2047, 998, 5, '2025-08-05', 4, 15000.00);
INSERT INTO public.service_usage VALUES (2048, 999, 4, '2025-08-09', 1, 1800.00);
INSERT INTO public.service_usage VALUES (2049, 1000, 1, '2025-08-14', 3, 2500.00);
INSERT INTO public.service_usage VALUES (2050, 1001, 1, '2025-08-17', 3, 2500.00);
INSERT INTO public.service_usage VALUES (2051, 1001, 7, '2025-08-21', 1, 12000.00);
INSERT INTO public.service_usage VALUES (2052, 1001, 3, '2025-08-19', 1, 3500.00);
INSERT INTO public.service_usage VALUES (2053, 1001, 3, '2025-08-19', 4, 3500.00);
INSERT INTO public.service_usage VALUES (2054, 1002, 4, '2025-08-24', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2055, 1002, 4, '2025-08-24', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2056, 1002, 3, '2025-08-25', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2057, 1002, 4, '2025-08-23', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2058, 1003, 5, '2025-08-30', 1, 15000.00);
INSERT INTO public.service_usage VALUES (2059, 1003, 5, '2025-08-30', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2060, 1003, 3, '2025-08-30', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2061, 1004, 5, '2025-09-03', 4, 15000.00);
INSERT INTO public.service_usage VALUES (2062, 1004, 7, '2025-09-03', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2063, 1004, 5, '2025-09-03', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2064, 1005, 5, '2025-09-06', 4, 15000.00);
INSERT INTO public.service_usage VALUES (2065, 1005, 4, '2025-09-09', 1, 1800.00);
INSERT INTO public.service_usage VALUES (2066, 1005, 5, '2025-09-07', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2067, 1007, 5, '2025-09-15', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2068, 1007, 2, '2025-09-12', 2, 6000.00);
INSERT INTO public.service_usage VALUES (2069, 1007, 2, '2025-09-13', 4, 6000.00);
INSERT INTO public.service_usage VALUES (2070, 1007, 6, '2025-09-14', 4, 600.00);
INSERT INTO public.service_usage VALUES (2071, 1008, 4, '2025-09-18', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2072, 1008, 2, '2025-09-17', 1, 6000.00);
INSERT INTO public.service_usage VALUES (2073, 1009, 5, '2025-09-21', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2074, 1009, 1, '2025-09-21', 1, 2500.00);
INSERT INTO public.service_usage VALUES (2075, 1009, 3, '2025-09-21', 1, 3500.00);
INSERT INTO public.service_usage VALUES (2076, 1010, 4, '2025-09-25', 3, 1800.00);
INSERT INTO public.service_usage VALUES (2077, 1010, 7, '2025-09-25', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2078, 1010, 4, '2025-09-25', 3, 1800.00);
INSERT INTO public.service_usage VALUES (2079, 1013, 4, '2025-07-06', 3, 1800.00);
INSERT INTO public.service_usage VALUES (2080, 1013, 1, '2025-07-05', 2, 2500.00);
INSERT INTO public.service_usage VALUES (2081, 1013, 3, '2025-07-04', 1, 3500.00);
INSERT INTO public.service_usage VALUES (2082, 1014, 2, '2025-07-12', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2083, 1014, 6, '2025-07-11', 3, 600.00);
INSERT INTO public.service_usage VALUES (2084, 1015, 2, '2025-07-18', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2085, 1015, 1, '2025-07-18', 3, 2500.00);
INSERT INTO public.service_usage VALUES (2086, 1015, 4, '2025-07-18', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2087, 1015, 5, '2025-07-18', 4, 15000.00);
INSERT INTO public.service_usage VALUES (2088, 1016, 2, '2025-07-21', 2, 6000.00);
INSERT INTO public.service_usage VALUES (2089, 1017, 4, '2025-07-28', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2090, 1017, 6, '2025-07-28', 4, 600.00);
INSERT INTO public.service_usage VALUES (2091, 1017, 3, '2025-07-27', 4, 3500.00);
INSERT INTO public.service_usage VALUES (2092, 1018, 6, '2025-07-30', 1, 600.00);
INSERT INTO public.service_usage VALUES (2093, 1018, 3, '2025-07-30', 4, 3500.00);
INSERT INTO public.service_usage VALUES (2094, 1020, 1, '2025-08-08', 3, 2500.00);
INSERT INTO public.service_usage VALUES (2095, 1020, 1, '2025-08-09', 1, 2500.00);
INSERT INTO public.service_usage VALUES (2096, 1021, 3, '2025-08-14', 1, 3500.00);
INSERT INTO public.service_usage VALUES (2097, 1021, 5, '2025-08-10', 1, 15000.00);
INSERT INTO public.service_usage VALUES (2098, 1021, 6, '2025-08-13', 4, 600.00);
INSERT INTO public.service_usage VALUES (2099, 1021, 6, '2025-08-14', 4, 600.00);
INSERT INTO public.service_usage VALUES (2100, 1022, 7, '2025-08-17', 4, 12000.00);
INSERT INTO public.service_usage VALUES (2101, 1023, 5, '2025-08-20', 1, 15000.00);
INSERT INTO public.service_usage VALUES (2102, 1024, 7, '2025-08-23', 4, 12000.00);
INSERT INTO public.service_usage VALUES (2103, 1024, 5, '2025-08-24', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2104, 1025, 5, '2025-08-29', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2105, 1025, 2, '2025-08-30', 1, 6000.00);
INSERT INTO public.service_usage VALUES (2106, 1026, 7, '2025-09-01', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2107, 1026, 5, '2025-09-02', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2108, 1026, 7, '2025-09-02', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2109, 1027, 2, '2025-09-08', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2110, 1027, 4, '2025-09-08', 3, 1800.00);
INSERT INTO public.service_usage VALUES (2111, 1027, 3, '2025-09-08', 1, 3500.00);
INSERT INTO public.service_usage VALUES (2112, 1028, 1, '2025-09-10', 1, 2500.00);
INSERT INTO public.service_usage VALUES (2113, 1028, 2, '2025-09-10', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2114, 1028, 4, '2025-09-10', 3, 1800.00);
INSERT INTO public.service_usage VALUES (2115, 1029, 5, '2025-09-13', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2116, 1030, 7, '2025-09-16', 4, 12000.00);
INSERT INTO public.service_usage VALUES (2117, 1031, 2, '2025-09-20', 1, 6000.00);
INSERT INTO public.service_usage VALUES (2118, 1031, 1, '2025-09-19', 1, 2500.00);
INSERT INTO public.service_usage VALUES (2119, 1032, 1, '2025-09-23', 2, 2500.00);
INSERT INTO public.service_usage VALUES (2120, 1032, 7, '2025-09-25', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2121, 1033, 3, '2025-09-28', 1, 3500.00);
INSERT INTO public.service_usage VALUES (2122, 1033, 2, '2025-09-28', 2, 6000.00);
INSERT INTO public.service_usage VALUES (2123, 1034, 7, '2025-07-01', 1, 12000.00);
INSERT INTO public.service_usage VALUES (2124, 1034, 7, '2025-07-02', 4, 12000.00);
INSERT INTO public.service_usage VALUES (2125, 1035, 6, '2025-07-05', 3, 600.00);
INSERT INTO public.service_usage VALUES (2126, 1035, 1, '2025-07-05', 4, 2500.00);
INSERT INTO public.service_usage VALUES (2127, 1035, 1, '2025-07-05', 3, 2500.00);
INSERT INTO public.service_usage VALUES (2128, 1037, 2, '2025-07-10', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2129, 1037, 2, '2025-07-10', 1, 6000.00);
INSERT INTO public.service_usage VALUES (2130, 1037, 2, '2025-07-11', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2131, 1038, 3, '2025-07-16', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2132, 1038, 7, '2025-07-16', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2133, 1041, 7, '2025-07-24', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2134, 1041, 6, '2025-07-24', 4, 600.00);
INSERT INTO public.service_usage VALUES (2135, 1041, 2, '2025-07-23', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2136, 1041, 1, '2025-07-23', 4, 2500.00);
INSERT INTO public.service_usage VALUES (2137, 1042, 7, '2025-07-27', 1, 12000.00);
INSERT INTO public.service_usage VALUES (2138, 1042, 1, '2025-07-26', 4, 2500.00);
INSERT INTO public.service_usage VALUES (2139, 1042, 2, '2025-07-26', 1, 6000.00);
INSERT INTO public.service_usage VALUES (2140, 1043, 5, '2025-07-30', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2141, 1043, 1, '2025-07-31', 1, 2500.00);
INSERT INTO public.service_usage VALUES (2142, 1044, 1, '2025-08-02', 1, 2500.00);
INSERT INTO public.service_usage VALUES (2143, 1044, 1, '2025-08-03', 3, 2500.00);
INSERT INTO public.service_usage VALUES (2144, 1044, 6, '2025-08-02', 2, 600.00);
INSERT INTO public.service_usage VALUES (2145, 1045, 7, '2025-08-06', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2146, 1045, 7, '2025-08-07', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2147, 1045, 2, '2025-08-07', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2148, 1046, 1, '2025-08-10', 3, 2500.00);
INSERT INTO public.service_usage VALUES (2149, 1046, 7, '2025-08-11', 4, 12000.00);
INSERT INTO public.service_usage VALUES (2150, 1047, 3, '2025-08-15', 2, 3500.00);
INSERT INTO public.service_usage VALUES (2151, 1048, 7, '2025-08-19', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2152, 1048, 3, '2025-08-19', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2153, 1048, 3, '2025-08-18', 4, 3500.00);
INSERT INTO public.service_usage VALUES (2154, 1050, 6, '2025-08-27', 3, 600.00);
INSERT INTO public.service_usage VALUES (2155, 1050, 4, '2025-08-25', 4, 1800.00);
INSERT INTO public.service_usage VALUES (2156, 1051, 1, '2025-08-29', 2, 2500.00);
INSERT INTO public.service_usage VALUES (2157, 1052, 3, '2025-09-02', 2, 3500.00);
INSERT INTO public.service_usage VALUES (2158, 1052, 6, '2025-09-02', 3, 600.00);
INSERT INTO public.service_usage VALUES (2159, 1053, 3, '2025-09-06', 1, 3500.00);
INSERT INTO public.service_usage VALUES (2160, 1054, 1, '2025-09-10', 4, 2500.00);
INSERT INTO public.service_usage VALUES (2161, 1054, 1, '2025-09-11', 2, 2500.00);
INSERT INTO public.service_usage VALUES (2162, 1055, 4, '2025-09-15', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2163, 1055, 1, '2025-09-17', 2, 2500.00);
INSERT INTO public.service_usage VALUES (2164, 1055, 3, '2025-09-15', 2, 3500.00);
INSERT INTO public.service_usage VALUES (2165, 1056, 7, '2025-09-19', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2166, 1056, 6, '2025-09-18', 3, 600.00);
INSERT INTO public.service_usage VALUES (2167, 1056, 7, '2025-09-19', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2168, 1056, 5, '2025-09-19', 4, 15000.00);
INSERT INTO public.service_usage VALUES (2169, 1057, 3, '2025-09-23', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2170, 1057, 3, '2025-09-23', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2171, 1058, 3, '2025-09-27', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2172, 1058, 5, '2025-09-29', 4, 15000.00);
INSERT INTO public.service_usage VALUES (2173, 1059, 6, '2025-07-02', 2, 600.00);
INSERT INTO public.service_usage VALUES (2174, 1060, 7, '2025-07-05', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2175, 1060, 3, '2025-07-05', 2, 3500.00);
INSERT INTO public.service_usage VALUES (2176, 1060, 7, '2025-07-05', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2177, 1061, 2, '2025-07-08', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2178, 1061, 2, '2025-07-08', 4, 6000.00);
INSERT INTO public.service_usage VALUES (2179, 1061, 2, '2025-07-08', 2, 6000.00);
INSERT INTO public.service_usage VALUES (2180, 1061, 3, '2025-07-08', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2181, 1062, 4, '2025-07-11', 3, 1800.00);
INSERT INTO public.service_usage VALUES (2182, 1062, 6, '2025-07-11', 3, 600.00);
INSERT INTO public.service_usage VALUES (2183, 1062, 7, '2025-07-12', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2184, 1063, 3, '2025-07-14', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2185, 1063, 7, '2025-07-14', 4, 12000.00);
INSERT INTO public.service_usage VALUES (2186, 1064, 5, '2025-07-16', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2187, 1064, 6, '2025-07-16', 4, 600.00);
INSERT INTO public.service_usage VALUES (2188, 1064, 7, '2025-07-16', 4, 12000.00);
INSERT INTO public.service_usage VALUES (2189, 1064, 7, '2025-07-16', 1, 12000.00);
INSERT INTO public.service_usage VALUES (2190, 1065, 7, '2025-07-19', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2191, 1066, 1, '2025-07-21', 4, 2500.00);
INSERT INTO public.service_usage VALUES (2192, 1066, 4, '2025-07-21', 1, 1800.00);
INSERT INTO public.service_usage VALUES (2193, 1068, 6, '2025-07-29', 4, 600.00);
INSERT INTO public.service_usage VALUES (2194, 1068, 6, '2025-07-28', 4, 600.00);
INSERT INTO public.service_usage VALUES (2195, 1069, 3, '2025-08-01', 1, 3500.00);
INSERT INTO public.service_usage VALUES (2196, 1069, 3, '2025-08-02', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2197, 1069, 3, '2025-08-02', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2198, 1070, 4, '2025-08-06', 4, 1800.00);
INSERT INTO public.service_usage VALUES (2199, 1070, 5, '2025-08-05', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2200, 1071, 1, '2025-08-08', 3, 2500.00);
INSERT INTO public.service_usage VALUES (2201, 1071, 2, '2025-08-08', 2, 6000.00);
INSERT INTO public.service_usage VALUES (2202, 1071, 3, '2025-08-08', 2, 3500.00);
INSERT INTO public.service_usage VALUES (2203, 1071, 3, '2025-08-08', 2, 3500.00);
INSERT INTO public.service_usage VALUES (2204, 1072, 6, '2025-08-09', 1, 600.00);
INSERT INTO public.service_usage VALUES (2205, 1072, 2, '2025-08-10', 4, 6000.00);
INSERT INTO public.service_usage VALUES (2206, 1072, 3, '2025-08-09', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2207, 1073, 7, '2025-08-12', 4, 12000.00);
INSERT INTO public.service_usage VALUES (2208, 1073, 2, '2025-08-12', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2209, 1073, 1, '2025-08-14', 2, 2500.00);
INSERT INTO public.service_usage VALUES (2210, 1074, 7, '2025-08-18', 1, 12000.00);
INSERT INTO public.service_usage VALUES (2211, 1075, 6, '2025-08-23', 4, 600.00);
INSERT INTO public.service_usage VALUES (2212, 1075, 2, '2025-08-24', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2213, 1075, 4, '2025-08-24', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2214, 1076, 1, '2025-08-26', 2, 2500.00);
INSERT INTO public.service_usage VALUES (2215, 1076, 4, '2025-08-26', 3, 1800.00);
INSERT INTO public.service_usage VALUES (2216, 1077, 7, '2025-08-30', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2217, 1077, 2, '2025-08-29', 1, 6000.00);
INSERT INTO public.service_usage VALUES (2218, 1077, 3, '2025-08-31', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2219, 1077, 7, '2025-08-29', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2220, 1078, 5, '2025-09-03', 4, 15000.00);
INSERT INTO public.service_usage VALUES (2221, 1078, 6, '2025-09-04', 1, 600.00);
INSERT INTO public.service_usage VALUES (2222, 1078, 3, '2025-09-04', 2, 3500.00);
INSERT INTO public.service_usage VALUES (2223, 1079, 3, '2025-09-10', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2224, 1079, 1, '2025-09-10', 2, 2500.00);
INSERT INTO public.service_usage VALUES (2225, 1079, 7, '2025-09-10', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2226, 1080, 6, '2025-09-16', 2, 600.00);
INSERT INTO public.service_usage VALUES (2227, 1080, 2, '2025-09-16', 4, 6000.00);
INSERT INTO public.service_usage VALUES (2228, 1080, 5, '2025-09-14', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2229, 1081, 6, '2025-09-21', 2, 600.00);
INSERT INTO public.service_usage VALUES (2230, 1081, 3, '2025-09-21', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2231, 1081, 2, '2025-09-20', 4, 6000.00);
INSERT INTO public.service_usage VALUES (2232, 1083, 6, '2025-09-30', 3, 600.00);
INSERT INTO public.service_usage VALUES (2233, 1083, 2, '2025-09-30', 2, 6000.00);
INSERT INTO public.service_usage VALUES (2234, 1083, 7, '2025-10-02', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2235, 1085, 1, '2025-07-04', 3, 2500.00);
INSERT INTO public.service_usage VALUES (2236, 1085, 7, '2025-07-04', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2237, 1085, 3, '2025-07-05', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2238, 1086, 6, '2025-07-11', 1, 600.00);
INSERT INTO public.service_usage VALUES (2239, 1087, 2, '2025-07-14', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2240, 1087, 2, '2025-07-14', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2241, 1088, 4, '2025-07-18', 3, 1800.00);
INSERT INTO public.service_usage VALUES (2242, 1088, 4, '2025-07-18', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2243, 1089, 6, '2025-07-21', 1, 600.00);
INSERT INTO public.service_usage VALUES (2244, 1089, 5, '2025-07-22', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2245, 1090, 4, '2025-07-24', 4, 1800.00);
INSERT INTO public.service_usage VALUES (2246, 1091, 2, '2025-07-29', 2, 6000.00);
INSERT INTO public.service_usage VALUES (2247, 1092, 3, '2025-08-01', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2248, 1092, 5, '2025-08-01', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2249, 1092, 5, '2025-08-01', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2250, 1093, 2, '2025-08-03', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2251, 1095, 4, '2025-08-10', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2252, 1095, 6, '2025-08-09', 2, 600.00);
INSERT INTO public.service_usage VALUES (2253, 1096, 3, '2025-08-12', 2, 3500.00);
INSERT INTO public.service_usage VALUES (2254, 1096, 1, '2025-08-12', 4, 2500.00);
INSERT INTO public.service_usage VALUES (2255, 1097, 2, '2025-08-16', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2256, 1097, 3, '2025-08-16', 2, 3500.00);
INSERT INTO public.service_usage VALUES (2257, 1097, 1, '2025-08-16', 4, 2500.00);
INSERT INTO public.service_usage VALUES (2258, 1097, 2, '2025-08-16', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2259, 1098, 5, '2025-08-17', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2260, 1099, 7, '2025-08-19', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2261, 1099, 3, '2025-08-19', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2262, 1100, 4, '2025-08-21', 3, 1800.00);
INSERT INTO public.service_usage VALUES (2263, 1100, 7, '2025-08-21', 1, 12000.00);
INSERT INTO public.service_usage VALUES (2264, 1101, 1, '2025-08-25', 3, 2500.00);
INSERT INTO public.service_usage VALUES (2265, 1102, 7, '2025-08-31', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2266, 1102, 6, '2025-08-31', 4, 600.00);
INSERT INTO public.service_usage VALUES (2267, 1103, 7, '2025-09-07', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2268, 1103, 7, '2025-09-08', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2269, 1103, 2, '2025-09-06', 1, 6000.00);
INSERT INTO public.service_usage VALUES (2270, 1103, 4, '2025-09-05', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2271, 1107, 7, '2025-09-26', 1, 12000.00);
INSERT INTO public.service_usage VALUES (2272, 1108, 4, '2025-09-29', 4, 1800.00);
INSERT INTO public.service_usage VALUES (2273, 1108, 4, '2025-09-29', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2274, 1108, 2, '2025-09-29', 4, 6000.00);
INSERT INTO public.service_usage VALUES (2275, 1108, 6, '2025-09-30', 2, 600.00);
INSERT INTO public.service_usage VALUES (2276, 1109, 1, '2025-07-01', 3, 2500.00);
INSERT INTO public.service_usage VALUES (2277, 1110, 5, '2025-07-04', 1, 15000.00);
INSERT INTO public.service_usage VALUES (2278, 1110, 5, '2025-07-05', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2279, 1111, 2, '2025-07-09', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2280, 1111, 5, '2025-07-08', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2281, 1111, 4, '2025-07-09', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2282, 1112, 3, '2025-07-14', 2, 3500.00);
INSERT INTO public.service_usage VALUES (2283, 1112, 5, '2025-07-13', 1, 15000.00);
INSERT INTO public.service_usage VALUES (2284, 1112, 6, '2025-07-13', 1, 600.00);
INSERT INTO public.service_usage VALUES (2285, 1113, 2, '2025-07-17', 2, 6000.00);
INSERT INTO public.service_usage VALUES (2286, 1113, 1, '2025-07-17', 1, 2500.00);
INSERT INTO public.service_usage VALUES (2287, 1114, 5, '2025-07-20', 1, 15000.00);
INSERT INTO public.service_usage VALUES (2288, 1114, 7, '2025-07-21', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2289, 1114, 5, '2025-07-22', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2290, 1115, 1, '2025-07-24', 2, 2500.00);
INSERT INTO public.service_usage VALUES (2291, 1116, 1, '2025-07-29', 3, 2500.00);
INSERT INTO public.service_usage VALUES (2292, 1117, 7, '2025-07-30', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2293, 1118, 1, '2025-08-06', 1, 2500.00);
INSERT INTO public.service_usage VALUES (2294, 1118, 3, '2025-08-05', 2, 3500.00);
INSERT INTO public.service_usage VALUES (2295, 1118, 5, '2025-08-05', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2296, 1118, 6, '2025-08-07', 2, 600.00);
INSERT INTO public.service_usage VALUES (2297, 1119, 7, '2025-08-10', 4, 12000.00);
INSERT INTO public.service_usage VALUES (2298, 1119, 7, '2025-08-09', 4, 12000.00);
INSERT INTO public.service_usage VALUES (2299, 1119, 1, '2025-08-09', 4, 2500.00);
INSERT INTO public.service_usage VALUES (2300, 1119, 3, '2025-08-09', 4, 3500.00);
INSERT INTO public.service_usage VALUES (2301, 1121, 1, '2025-08-13', 2, 2500.00);
INSERT INTO public.service_usage VALUES (2302, 1121, 7, '2025-08-13', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2303, 1121, 7, '2025-08-13', 4, 12000.00);
INSERT INTO public.service_usage VALUES (2304, 1121, 5, '2025-08-13', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2305, 1124, 4, '2025-08-26', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2306, 1124, 5, '2025-08-26', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2307, 1124, 2, '2025-08-26', 2, 6000.00);
INSERT INTO public.service_usage VALUES (2308, 1125, 5, '2025-08-28', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2309, 1126, 3, '2025-08-31', 1, 3500.00);
INSERT INTO public.service_usage VALUES (2310, 1126, 7, '2025-09-01', 4, 12000.00);
INSERT INTO public.service_usage VALUES (2311, 1126, 5, '2025-08-31', 4, 15000.00);
INSERT INTO public.service_usage VALUES (2312, 1126, 4, '2025-08-31', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2313, 1127, 1, '2025-09-04', 2, 2500.00);
INSERT INTO public.service_usage VALUES (2314, 1127, 1, '2025-09-06', 2, 2500.00);
INSERT INTO public.service_usage VALUES (2315, 1127, 3, '2025-09-04', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2316, 1128, 5, '2025-09-09', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2317, 1128, 4, '2025-09-08', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2318, 1129, 4, '2025-09-11', 3, 1800.00);
INSERT INTO public.service_usage VALUES (2319, 1132, 3, '2025-09-21', 4, 3500.00);
INSERT INTO public.service_usage VALUES (2320, 1132, 6, '2025-09-21', 3, 600.00);
INSERT INTO public.service_usage VALUES (2321, 1133, 3, '2025-09-27', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2322, 1134, 5, '2025-09-30', 1, 15000.00);
INSERT INTO public.service_usage VALUES (2323, 1134, 5, '2025-09-30', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2324, 1135, 6, '2025-07-02', 3, 600.00);
INSERT INTO public.service_usage VALUES (2325, 1135, 6, '2025-07-04', 3, 600.00);
INSERT INTO public.service_usage VALUES (2326, 1135, 5, '2025-07-02', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2327, 1136, 7, '2025-07-06', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2328, 1136, 3, '2025-07-05', 2, 3500.00);
INSERT INTO public.service_usage VALUES (2329, 1136, 6, '2025-07-06', 3, 600.00);
INSERT INTO public.service_usage VALUES (2330, 1136, 2, '2025-07-05', 4, 6000.00);
INSERT INTO public.service_usage VALUES (2331, 1137, 2, '2025-07-10', 2, 6000.00);
INSERT INTO public.service_usage VALUES (2332, 1137, 4, '2025-07-09', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2333, 1137, 7, '2025-07-09', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2334, 1137, 7, '2025-07-09', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2335, 1138, 6, '2025-07-12', 1, 600.00);
INSERT INTO public.service_usage VALUES (2336, 1138, 1, '2025-07-13', 3, 2500.00);
INSERT INTO public.service_usage VALUES (2337, 1138, 7, '2025-07-14', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2338, 1138, 7, '2025-07-12', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2339, 1139, 4, '2025-07-19', 4, 1800.00);
INSERT INTO public.service_usage VALUES (2340, 1140, 7, '2025-07-25', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2341, 1140, 6, '2025-07-24', 2, 600.00);
INSERT INTO public.service_usage VALUES (2342, 1140, 7, '2025-07-25', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2343, 1141, 3, '2025-07-28', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2344, 1141, 6, '2025-07-28', 1, 600.00);
INSERT INTO public.service_usage VALUES (2345, 1142, 2, '2025-08-02', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2346, 1143, 1, '2025-08-05', 2, 2500.00);
INSERT INTO public.service_usage VALUES (2347, 1143, 7, '2025-08-05', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2348, 1143, 2, '2025-08-05', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2349, 1144, 1, '2025-08-07', 2, 2500.00);
INSERT INTO public.service_usage VALUES (2350, 1145, 7, '2025-08-11', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2351, 1145, 1, '2025-08-10', 4, 2500.00);
INSERT INTO public.service_usage VALUES (2352, 1145, 5, '2025-08-11', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2353, 1146, 3, '2025-08-15', 2, 3500.00);
INSERT INTO public.service_usage VALUES (2354, 1146, 2, '2025-08-16', 4, 6000.00);
INSERT INTO public.service_usage VALUES (2355, 1147, 3, '2025-08-19', 2, 3500.00);
INSERT INTO public.service_usage VALUES (2356, 1147, 3, '2025-08-19', 2, 3500.00);
INSERT INTO public.service_usage VALUES (2357, 1147, 1, '2025-08-19', 3, 2500.00);
INSERT INTO public.service_usage VALUES (2358, 1148, 3, '2025-08-22', 2, 3500.00);
INSERT INTO public.service_usage VALUES (2359, 1149, 6, '2025-08-26', 3, 600.00);
INSERT INTO public.service_usage VALUES (2360, 1150, 6, '2025-08-30', 3, 600.00);
INSERT INTO public.service_usage VALUES (2361, 1150, 7, '2025-08-29', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2362, 1151, 6, '2025-09-01', 4, 600.00);
INSERT INTO public.service_usage VALUES (2363, 1152, 6, '2025-09-08', 4, 600.00);
INSERT INTO public.service_usage VALUES (2364, 1152, 4, '2025-09-06', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2365, 1153, 2, '2025-09-16', 1, 6000.00);
INSERT INTO public.service_usage VALUES (2366, 1154, 3, '2025-09-20', 4, 3500.00);
INSERT INTO public.service_usage VALUES (2367, 1154, 2, '2025-09-20', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2368, 1154, 4, '2025-09-20', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2369, 1154, 4, '2025-09-20', 1, 1800.00);
INSERT INTO public.service_usage VALUES (2370, 1155, 7, '2025-09-26', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2371, 1155, 1, '2025-09-24', 2, 2500.00);
INSERT INTO public.service_usage VALUES (2372, 1156, 7, '2025-10-02', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2373, 1156, 2, '2025-10-02', 2, 6000.00);
INSERT INTO public.service_usage VALUES (2374, 1156, 4, '2025-09-30', 4, 1800.00);
INSERT INTO public.service_usage VALUES (2375, 1157, 7, '2025-07-01', 4, 12000.00);
INSERT INTO public.service_usage VALUES (2376, 1158, 7, '2025-07-07', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2377, 1158, 7, '2025-07-06', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2378, 1158, 3, '2025-07-06', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2379, 1159, 6, '2025-07-12', 1, 600.00);
INSERT INTO public.service_usage VALUES (2380, 1159, 3, '2025-07-10', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2381, 1159, 4, '2025-07-12', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2382, 1160, 7, '2025-07-15', 4, 12000.00);
INSERT INTO public.service_usage VALUES (2383, 1160, 7, '2025-07-15', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2384, 1160, 2, '2025-07-16', 1, 6000.00);
INSERT INTO public.service_usage VALUES (2385, 1161, 3, '2025-07-20', 1, 3500.00);
INSERT INTO public.service_usage VALUES (2386, 1161, 5, '2025-07-19', 1, 15000.00);
INSERT INTO public.service_usage VALUES (2387, 1162, 2, '2025-07-23', 1, 6000.00);
INSERT INTO public.service_usage VALUES (2388, 1162, 5, '2025-07-23', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2389, 1164, 2, '2025-07-27', 4, 6000.00);
INSERT INTO public.service_usage VALUES (2390, 1165, 1, '2025-07-31', 4, 2500.00);
INSERT INTO public.service_usage VALUES (2391, 1166, 4, '2025-08-02', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2392, 1166, 6, '2025-08-04', 3, 600.00);
INSERT INTO public.service_usage VALUES (2393, 1166, 7, '2025-08-01', 4, 12000.00);
INSERT INTO public.service_usage VALUES (2394, 1167, 6, '2025-08-06', 1, 600.00);
INSERT INTO public.service_usage VALUES (2395, 1168, 1, '2025-08-12', 3, 2500.00);
INSERT INTO public.service_usage VALUES (2396, 1169, 1, '2025-08-17', 3, 2500.00);
INSERT INTO public.service_usage VALUES (2397, 1169, 7, '2025-08-17', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2398, 1169, 5, '2025-08-15', 4, 15000.00);
INSERT INTO public.service_usage VALUES (2399, 1170, 5, '2025-08-22', 4, 15000.00);
INSERT INTO public.service_usage VALUES (2400, 1170, 1, '2025-08-23', 2, 2500.00);
INSERT INTO public.service_usage VALUES (2401, 1170, 7, '2025-08-22', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2402, 1171, 7, '2025-08-28', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2403, 1171, 6, '2025-08-28', 3, 600.00);
INSERT INTO public.service_usage VALUES (2404, 1171, 3, '2025-08-28', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2405, 1172, 2, '2025-09-01', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2406, 1173, 2, '2025-09-03', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2407, 1174, 3, '2025-09-06', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2408, 1174, 6, '2025-09-06', 4, 600.00);
INSERT INTO public.service_usage VALUES (2409, 1174, 5, '2025-09-07', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2410, 1175, 4, '2025-09-11', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2411, 1175, 5, '2025-09-10', 4, 15000.00);
INSERT INTO public.service_usage VALUES (2412, 1176, 6, '2025-09-16', 2, 600.00);
INSERT INTO public.service_usage VALUES (2413, 1177, 1, '2025-09-20', 3, 2500.00);
INSERT INTO public.service_usage VALUES (2414, 1177, 1, '2025-09-20', 4, 2500.00);
INSERT INTO public.service_usage VALUES (2415, 1177, 4, '2025-09-20', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2416, 1177, 4, '2025-09-20', 1, 1800.00);
INSERT INTO public.service_usage VALUES (2417, 1178, 3, '2025-09-22', 2, 3500.00);
INSERT INTO public.service_usage VALUES (2418, 1178, 5, '2025-09-22', 1, 15000.00);
INSERT INTO public.service_usage VALUES (2419, 1178, 1, '2025-09-22', 4, 2500.00);
INSERT INTO public.service_usage VALUES (2420, 1178, 5, '2025-09-22', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2421, 1180, 3, '2025-10-01', 4, 3500.00);
INSERT INTO public.service_usage VALUES (2422, 1180, 7, '2025-09-30', 1, 12000.00);
INSERT INTO public.service_usage VALUES (2423, 1180, 4, '2025-10-02', 1, 1800.00);
INSERT INTO public.service_usage VALUES (2424, 1180, 4, '2025-10-02', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2425, 1181, 3, '2025-07-01', 2, 3500.00);
INSERT INTO public.service_usage VALUES (2426, 1181, 3, '2025-07-01', 2, 3500.00);
INSERT INTO public.service_usage VALUES (2427, 1181, 7, '2025-07-01', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2428, 1182, 7, '2025-07-04', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2429, 1182, 4, '2025-07-05', 3, 1800.00);
INSERT INTO public.service_usage VALUES (2430, 1184, 4, '2025-07-13', 1, 1800.00);
INSERT INTO public.service_usage VALUES (2431, 1184, 4, '2025-07-13', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2432, 1184, 2, '2025-07-13', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2433, 1185, 3, '2025-07-18', 2, 3500.00);
INSERT INTO public.service_usage VALUES (2434, 1185, 4, '2025-07-16', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2435, 1185, 6, '2025-07-18', 3, 600.00);
INSERT INTO public.service_usage VALUES (2436, 1186, 4, '2025-07-21', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2437, 1187, 4, '2025-07-26', 4, 1800.00);
INSERT INTO public.service_usage VALUES (2438, 1187, 1, '2025-07-26', 2, 2500.00);
INSERT INTO public.service_usage VALUES (2439, 1187, 4, '2025-07-26', 4, 1800.00);
INSERT INTO public.service_usage VALUES (2440, 1187, 1, '2025-07-26', 4, 2500.00);
INSERT INTO public.service_usage VALUES (2441, 1188, 4, '2025-07-29', 3, 1800.00);
INSERT INTO public.service_usage VALUES (2442, 1188, 5, '2025-07-29', 4, 15000.00);
INSERT INTO public.service_usage VALUES (2443, 1188, 5, '2025-07-29', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2444, 1189, 5, '2025-07-31', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2445, 1190, 6, '2025-08-05', 2, 600.00);
INSERT INTO public.service_usage VALUES (2446, 1191, 6, '2025-08-07', 2, 600.00);
INSERT INTO public.service_usage VALUES (2447, 1192, 7, '2025-08-14', 1, 12000.00);
INSERT INTO public.service_usage VALUES (2448, 1192, 2, '2025-08-15', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2449, 1192, 4, '2025-08-14', 3, 1800.00);
INSERT INTO public.service_usage VALUES (2450, 1194, 6, '2025-08-21', 2, 600.00);
INSERT INTO public.service_usage VALUES (2451, 1194, 2, '2025-08-21', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2452, 1194, 1, '2025-08-20', 4, 2500.00);
INSERT INTO public.service_usage VALUES (2453, 1194, 2, '2025-08-20', 1, 6000.00);
INSERT INTO public.service_usage VALUES (2454, 1195, 1, '2025-08-25', 2, 2500.00);
INSERT INTO public.service_usage VALUES (2455, 1195, 4, '2025-08-24', 3, 1800.00);
INSERT INTO public.service_usage VALUES (2456, 1195, 7, '2025-08-26', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2457, 1196, 3, '2025-08-30', 4, 3500.00);
INSERT INTO public.service_usage VALUES (2458, 1198, 1, '2025-09-05', 3, 2500.00);
INSERT INTO public.service_usage VALUES (2459, 1199, 4, '2025-09-10', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2460, 1199, 2, '2025-09-09', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2461, 1200, 5, '2025-09-14', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2462, 1200, 7, '2025-09-14', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2463, 1201, 3, '2025-09-16', 2, 3500.00);
INSERT INTO public.service_usage VALUES (2464, 1202, 1, '2025-09-19', 2, 2500.00);
INSERT INTO public.service_usage VALUES (2465, 1202, 7, '2025-09-19', 1, 12000.00);
INSERT INTO public.service_usage VALUES (2466, 1203, 2, '2025-09-25', 1, 6000.00);
INSERT INTO public.service_usage VALUES (2467, 1203, 7, '2025-09-23', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2468, 1203, 3, '2025-09-22', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2469, 1203, 4, '2025-09-24', 4, 1800.00);
INSERT INTO public.service_usage VALUES (2470, 1204, 4, '2025-09-29', 3, 1800.00);
INSERT INTO public.service_usage VALUES (2471, 1204, 2, '2025-09-30', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2472, 1205, 4, '2025-07-01', 3, 1800.00);
INSERT INTO public.service_usage VALUES (2473, 1205, 4, '2025-07-01', 1, 1800.00);
INSERT INTO public.service_usage VALUES (2474, 1205, 2, '2025-07-01', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2475, 1206, 7, '2025-07-04', 4, 12000.00);
INSERT INTO public.service_usage VALUES (2476, 1206, 7, '2025-07-06', 1, 12000.00);
INSERT INTO public.service_usage VALUES (2477, 1206, 5, '2025-07-06', 4, 15000.00);
INSERT INTO public.service_usage VALUES (2478, 1207, 5, '2025-07-09', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2479, 1207, 6, '2025-07-10', 1, 600.00);
INSERT INTO public.service_usage VALUES (2480, 1208, 4, '2025-07-15', 3, 1800.00);
INSERT INTO public.service_usage VALUES (2481, 1208, 2, '2025-07-15', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2482, 1208, 6, '2025-07-14', 2, 600.00);
INSERT INTO public.service_usage VALUES (2483, 1208, 5, '2025-07-16', 4, 15000.00);
INSERT INTO public.service_usage VALUES (2484, 1209, 4, '2025-07-20', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2485, 1209, 3, '2025-07-20', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2486, 1209, 1, '2025-07-21', 3, 2500.00);
INSERT INTO public.service_usage VALUES (2487, 1210, 4, '2025-07-26', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2488, 1211, 5, '2025-07-29', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2489, 1211, 5, '2025-07-28', 1, 15000.00);
INSERT INTO public.service_usage VALUES (2490, 1211, 5, '2025-07-28', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2491, 1213, 7, '2025-08-04', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2492, 1214, 2, '2025-08-09', 2, 6000.00);
INSERT INTO public.service_usage VALUES (2493, 1214, 6, '2025-08-09', 1, 600.00);
INSERT INTO public.service_usage VALUES (2494, 1215, 2, '2025-08-11', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2495, 1215, 1, '2025-08-12', 2, 2500.00);
INSERT INTO public.service_usage VALUES (2496, 1216, 1, '2025-08-16', 1, 2500.00);
INSERT INTO public.service_usage VALUES (2497, 1216, 2, '2025-08-14', 4, 6000.00);
INSERT INTO public.service_usage VALUES (2498, 1216, 3, '2025-08-14', 4, 3500.00);
INSERT INTO public.service_usage VALUES (2499, 1217, 2, '2025-08-18', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2500, 1217, 1, '2025-08-18', 2, 2500.00);
INSERT INTO public.service_usage VALUES (2501, 1217, 4, '2025-08-17', 4, 1800.00);
INSERT INTO public.service_usage VALUES (2502, 1217, 7, '2025-08-18', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2503, 1218, 1, '2025-08-22', 3, 2500.00);
INSERT INTO public.service_usage VALUES (2504, 1218, 4, '2025-08-21', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2505, 1218, 3, '2025-08-21', 1, 3500.00);
INSERT INTO public.service_usage VALUES (2506, 1218, 6, '2025-08-22', 2, 600.00);
INSERT INTO public.service_usage VALUES (2507, 1220, 3, '2025-08-25', 1, 3500.00);
INSERT INTO public.service_usage VALUES (2508, 1220, 2, '2025-08-25', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2509, 1221, 4, '2025-08-29', 3, 1800.00);
INSERT INTO public.service_usage VALUES (2510, 1221, 2, '2025-08-28', 2, 6000.00);
INSERT INTO public.service_usage VALUES (2511, 1222, 5, '2025-08-30', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2512, 1222, 1, '2025-08-31', 2, 2500.00);
INSERT INTO public.service_usage VALUES (2513, 1222, 2, '2025-08-30', 2, 6000.00);
INSERT INTO public.service_usage VALUES (2514, 1223, 2, '2025-09-04', 2, 6000.00);
INSERT INTO public.service_usage VALUES (2515, 1223, 5, '2025-09-05', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2516, 1223, 2, '2025-09-03', 2, 6000.00);
INSERT INTO public.service_usage VALUES (2517, 1225, 1, '2025-09-14', 2, 2500.00);
INSERT INTO public.service_usage VALUES (2518, 1225, 5, '2025-09-14', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2519, 1225, 2, '2025-09-14', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2520, 1225, 1, '2025-09-14', 1, 2500.00);
INSERT INTO public.service_usage VALUES (2521, 1226, 5, '2025-09-18', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2522, 1226, 1, '2025-09-18', 2, 2500.00);
INSERT INTO public.service_usage VALUES (2523, 1226, 3, '2025-09-18', 2, 3500.00);
INSERT INTO public.service_usage VALUES (2524, 1227, 7, '2025-09-21', 4, 12000.00);
INSERT INTO public.service_usage VALUES (2525, 1227, 4, '2025-09-20', 3, 1800.00);
INSERT INTO public.service_usage VALUES (2526, 1228, 1, '2025-09-25', 4, 2500.00);
INSERT INTO public.service_usage VALUES (2527, 1229, 7, '2025-09-28', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2528, 1229, 7, '2025-09-29', 1, 12000.00);
INSERT INTO public.service_usage VALUES (2529, 1229, 5, '2025-09-28', 4, 15000.00);
INSERT INTO public.service_usage VALUES (2530, 1230, 7, '2025-07-01', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2531, 1232, 3, '2025-07-11', 2, 3500.00);
INSERT INTO public.service_usage VALUES (2532, 1232, 1, '2025-07-12', 3, 2500.00);
INSERT INTO public.service_usage VALUES (2533, 1232, 5, '2025-07-11', 4, 15000.00);
INSERT INTO public.service_usage VALUES (2534, 1233, 4, '2025-07-16', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2535, 1233, 3, '2025-07-17', 2, 3500.00);
INSERT INTO public.service_usage VALUES (2536, 1233, 5, '2025-07-17', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2537, 1234, 1, '2025-07-21', 2, 2500.00);
INSERT INTO public.service_usage VALUES (2538, 1234, 7, '2025-07-22', 1, 12000.00);
INSERT INTO public.service_usage VALUES (2539, 1234, 2, '2025-07-21', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2540, 1234, 3, '2025-07-21', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2541, 1236, 7, '2025-07-29', 1, 12000.00);
INSERT INTO public.service_usage VALUES (2542, 1236, 5, '2025-07-31', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2543, 1236, 7, '2025-07-29', 1, 12000.00);
INSERT INTO public.service_usage VALUES (2544, 1237, 1, '2025-08-02', 4, 2500.00);
INSERT INTO public.service_usage VALUES (2545, 1237, 1, '2025-08-02', 2, 2500.00);
INSERT INTO public.service_usage VALUES (2546, 1237, 5, '2025-08-02', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2547, 1238, 3, '2025-08-06', 2, 3500.00);
INSERT INTO public.service_usage VALUES (2548, 1239, 1, '2025-08-12', 4, 2500.00);
INSERT INTO public.service_usage VALUES (2549, 1239, 3, '2025-08-14', 1, 3500.00);
INSERT INTO public.service_usage VALUES (2550, 1239, 5, '2025-08-12', 1, 15000.00);
INSERT INTO public.service_usage VALUES (2551, 1240, 4, '2025-08-19', 3, 1800.00);
INSERT INTO public.service_usage VALUES (2552, 1240, 6, '2025-08-18', 2, 600.00);
INSERT INTO public.service_usage VALUES (2553, 1240, 4, '2025-08-17', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2554, 1242, 7, '2025-08-26', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2555, 1244, 4, '2025-09-06', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2556, 1245, 6, '2025-09-08', 4, 600.00);
INSERT INTO public.service_usage VALUES (2557, 1245, 4, '2025-09-08', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2558, 1246, 4, '2025-09-14', 4, 1800.00);
INSERT INTO public.service_usage VALUES (2559, 1246, 4, '2025-09-15', 3, 1800.00);
INSERT INTO public.service_usage VALUES (2560, 1247, 5, '2025-09-19', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2561, 1248, 6, '2025-09-25', 1, 600.00);
INSERT INTO public.service_usage VALUES (2562, 1248, 6, '2025-09-26', 2, 600.00);
INSERT INTO public.service_usage VALUES (2563, 1248, 7, '2025-09-24', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2564, 1248, 7, '2025-09-25', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2565, 1249, 4, '2025-09-30', 4, 1800.00);
INSERT INTO public.service_usage VALUES (2566, 1249, 3, '2025-09-27', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2567, 1250, 7, '2025-07-02', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2568, 1250, 2, '2025-07-02', 2, 6000.00);
INSERT INTO public.service_usage VALUES (2569, 1251, 6, '2025-07-06', 3, 600.00);
INSERT INTO public.service_usage VALUES (2570, 1251, 3, '2025-07-06', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2571, 1251, 6, '2025-07-05', 3, 600.00);
INSERT INTO public.service_usage VALUES (2572, 1251, 5, '2025-07-06', 1, 15000.00);
INSERT INTO public.service_usage VALUES (2573, 1252, 5, '2025-07-09', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2574, 1253, 6, '2025-07-12', 3, 600.00);
INSERT INTO public.service_usage VALUES (2575, 1253, 7, '2025-07-12', 1, 12000.00);
INSERT INTO public.service_usage VALUES (2576, 1254, 6, '2025-07-16', 1, 600.00);
INSERT INTO public.service_usage VALUES (2577, 1254, 5, '2025-07-16', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2578, 1254, 3, '2025-07-16', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2579, 1255, 5, '2025-07-21', 1, 15000.00);
INSERT INTO public.service_usage VALUES (2580, 1256, 5, '2025-07-23', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2581, 1258, 2, '2025-08-02', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2582, 1258, 4, '2025-08-01', 1, 1800.00);
INSERT INTO public.service_usage VALUES (2583, 1258, 3, '2025-08-01', 1, 3500.00);
INSERT INTO public.service_usage VALUES (2584, 1259, 4, '2025-08-06', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2585, 1259, 5, '2025-08-06', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2586, 1259, 7, '2025-08-05', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2587, 1260, 7, '2025-08-12', 4, 12000.00);
INSERT INTO public.service_usage VALUES (2588, 1260, 7, '2025-08-12', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2589, 1261, 1, '2025-08-17', 2, 2500.00);
INSERT INTO public.service_usage VALUES (2590, 1261, 7, '2025-08-17', 1, 12000.00);
INSERT INTO public.service_usage VALUES (2591, 1261, 6, '2025-08-17', 3, 600.00);
INSERT INTO public.service_usage VALUES (2592, 1263, 6, '2025-08-22', 3, 600.00);
INSERT INTO public.service_usage VALUES (2593, 1263, 2, '2025-08-22', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2594, 1264, 6, '2025-08-23', 3, 600.00);
INSERT INTO public.service_usage VALUES (2595, 1264, 6, '2025-08-23', 3, 600.00);
INSERT INTO public.service_usage VALUES (2596, 1265, 2, '2025-08-27', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2597, 1265, 7, '2025-08-26', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2598, 1265, 5, '2025-08-26', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2599, 1266, 2, '2025-08-30', 2, 6000.00);
INSERT INTO public.service_usage VALUES (2600, 1266, 4, '2025-08-30', 4, 1800.00);
INSERT INTO public.service_usage VALUES (2601, 1266, 3, '2025-08-31', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2602, 1266, 5, '2025-08-30', 4, 15000.00);
INSERT INTO public.service_usage VALUES (2603, 1267, 5, '2025-09-03', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2604, 1267, 1, '2025-09-03', 4, 2500.00);
INSERT INTO public.service_usage VALUES (2605, 1267, 6, '2025-09-03', 3, 600.00);
INSERT INTO public.service_usage VALUES (2606, 1268, 6, '2025-09-08', 2, 600.00);
INSERT INTO public.service_usage VALUES (2607, 1268, 5, '2025-09-09', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2608, 1268, 3, '2025-09-10', 2, 3500.00);
INSERT INTO public.service_usage VALUES (2609, 1269, 2, '2025-09-13', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2610, 1270, 3, '2025-09-16', 1, 3500.00);
INSERT INTO public.service_usage VALUES (2611, 1270, 1, '2025-09-16', 1, 2500.00);
INSERT INTO public.service_usage VALUES (2612, 1270, 1, '2025-09-16', 2, 2500.00);
INSERT INTO public.service_usage VALUES (2613, 1270, 7, '2025-09-16', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2614, 1271, 7, '2025-09-18', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2615, 1271, 1, '2025-09-18', 2, 2500.00);
INSERT INTO public.service_usage VALUES (2616, 1272, 3, '2025-09-23', 4, 3500.00);
INSERT INTO public.service_usage VALUES (2617, 1272, 4, '2025-09-23', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2618, 1272, 6, '2025-09-22', 3, 600.00);
INSERT INTO public.service_usage VALUES (2619, 1274, 6, '2025-10-03', 3, 600.00);
INSERT INTO public.service_usage VALUES (2620, 1275, 5, '2025-07-01', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2621, 1275, 4, '2025-07-01', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2622, 1275, 6, '2025-07-02', 4, 600.00);
INSERT INTO public.service_usage VALUES (2623, 1275, 6, '2025-07-01', 1, 600.00);
INSERT INTO public.service_usage VALUES (2624, 1276, 5, '2025-07-06', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2625, 1277, 1, '2025-07-09', 4, 2500.00);
INSERT INTO public.service_usage VALUES (2626, 1278, 6, '2025-07-14', 3, 600.00);
INSERT INTO public.service_usage VALUES (2627, 1278, 6, '2025-07-13', 1, 600.00);
INSERT INTO public.service_usage VALUES (2628, 1278, 6, '2025-07-12', 4, 600.00);
INSERT INTO public.service_usage VALUES (2629, 1278, 6, '2025-07-11', 3, 600.00);
INSERT INTO public.service_usage VALUES (2630, 1279, 4, '2025-07-17', 4, 1800.00);
INSERT INTO public.service_usage VALUES (2631, 1279, 2, '2025-07-18', 1, 6000.00);
INSERT INTO public.service_usage VALUES (2632, 1279, 5, '2025-07-17', 4, 15000.00);
INSERT INTO public.service_usage VALUES (2633, 1280, 2, '2025-07-24', 2, 6000.00);
INSERT INTO public.service_usage VALUES (2634, 1280, 1, '2025-07-22', 3, 2500.00);
INSERT INTO public.service_usage VALUES (2635, 1280, 7, '2025-07-23', 1, 12000.00);
INSERT INTO public.service_usage VALUES (2636, 1281, 7, '2025-07-25', 1, 12000.00);
INSERT INTO public.service_usage VALUES (2637, 1281, 3, '2025-07-25', 4, 3500.00);
INSERT INTO public.service_usage VALUES (2638, 1282, 2, '2025-07-28', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2639, 1282, 7, '2025-07-28', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2640, 1282, 1, '2025-07-29', 4, 2500.00);
INSERT INTO public.service_usage VALUES (2641, 1284, 5, '2025-08-06', 4, 15000.00);
INSERT INTO public.service_usage VALUES (2642, 1284, 2, '2025-08-04', 1, 6000.00);
INSERT INTO public.service_usage VALUES (2643, 1284, 6, '2025-08-04', 3, 600.00);
INSERT INTO public.service_usage VALUES (2644, 1285, 3, '2025-08-09', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2645, 1286, 7, '2025-08-17', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2646, 1287, 1, '2025-08-20', 4, 2500.00);
INSERT INTO public.service_usage VALUES (2647, 1287, 7, '2025-08-20', 4, 12000.00);
INSERT INTO public.service_usage VALUES (2648, 1287, 2, '2025-08-21', 4, 6000.00);
INSERT INTO public.service_usage VALUES (2649, 1288, 6, '2025-08-26', 3, 600.00);
INSERT INTO public.service_usage VALUES (2650, 1289, 5, '2025-08-28', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2651, 1289, 1, '2025-08-28', 1, 2500.00);
INSERT INTO public.service_usage VALUES (2652, 1289, 6, '2025-08-30', 2, 600.00);
INSERT INTO public.service_usage VALUES (2653, 1289, 7, '2025-08-28', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2654, 1290, 7, '2025-09-01', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2655, 1291, 5, '2025-09-04', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2656, 1291, 2, '2025-09-04', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2657, 1291, 1, '2025-09-04', 2, 2500.00);
INSERT INTO public.service_usage VALUES (2658, 1292, 4, '2025-09-06', 3, 1800.00);
INSERT INTO public.service_usage VALUES (2659, 1293, 7, '2025-09-12', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2660, 1293, 4, '2025-09-10', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2661, 1294, 3, '2025-09-16', 2, 3500.00);
INSERT INTO public.service_usage VALUES (2662, 1294, 3, '2025-09-15', 2, 3500.00);
INSERT INTO public.service_usage VALUES (2663, 1295, 2, '2025-09-20', 2, 6000.00);
INSERT INTO public.service_usage VALUES (2664, 1295, 2, '2025-09-20', 2, 6000.00);
INSERT INTO public.service_usage VALUES (2665, 1295, 5, '2025-09-20', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2666, 1297, 4, '2025-09-27', 1, 1800.00);
INSERT INTO public.service_usage VALUES (2667, 1297, 5, '2025-09-27', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2668, 1297, 1, '2025-09-25', 3, 2500.00);
INSERT INTO public.service_usage VALUES (2669, 1298, 7, '2025-10-01', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2670, 1298, 3, '2025-10-01', 2, 3500.00);
INSERT INTO public.service_usage VALUES (2671, 1298, 6, '2025-10-01', 1, 600.00);
INSERT INTO public.service_usage VALUES (2672, 1300, 4, '2025-07-05', 1, 1800.00);
INSERT INTO public.service_usage VALUES (2673, 1300, 3, '2025-07-06', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2674, 1300, 7, '2025-07-05', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2675, 1301, 6, '2025-07-07', 2, 600.00);
INSERT INTO public.service_usage VALUES (2676, 1301, 2, '2025-07-07', 4, 6000.00);
INSERT INTO public.service_usage VALUES (2677, 1301, 1, '2025-07-07', 3, 2500.00);
INSERT INTO public.service_usage VALUES (2678, 1302, 5, '2025-07-12', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2679, 1303, 2, '2025-07-17', 1, 6000.00);
INSERT INTO public.service_usage VALUES (2680, 1303, 5, '2025-07-16', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2681, 1303, 1, '2025-07-17', 1, 2500.00);
INSERT INTO public.service_usage VALUES (2682, 1303, 7, '2025-07-17', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2683, 1304, 5, '2025-07-19', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2684, 1305, 3, '2025-07-21', 1, 3500.00);
INSERT INTO public.service_usage VALUES (2685, 1306, 2, '2025-07-29', 2, 6000.00);
INSERT INTO public.service_usage VALUES (2686, 1306, 2, '2025-07-28', 2, 6000.00);
INSERT INTO public.service_usage VALUES (2687, 1307, 6, '2025-07-31', 4, 600.00);
INSERT INTO public.service_usage VALUES (2688, 1307, 2, '2025-08-01', 4, 6000.00);
INSERT INTO public.service_usage VALUES (2689, 1307, 4, '2025-07-31', 3, 1800.00);
INSERT INTO public.service_usage VALUES (2690, 1307, 7, '2025-08-01', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2691, 1308, 5, '2025-08-04', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2692, 1308, 2, '2025-08-03', 1, 6000.00);
INSERT INTO public.service_usage VALUES (2693, 1310, 4, '2025-08-11', 3, 1800.00);
INSERT INTO public.service_usage VALUES (2694, 1310, 5, '2025-08-13', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2695, 1310, 7, '2025-08-12', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2696, 1312, 6, '2025-08-21', 2, 600.00);
INSERT INTO public.service_usage VALUES (2697, 1312, 3, '2025-08-24', 2, 3500.00);
INSERT INTO public.service_usage VALUES (2698, 1313, 5, '2025-08-29', 1, 15000.00);
INSERT INTO public.service_usage VALUES (2699, 1313, 5, '2025-08-29', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2700, 1313, 7, '2025-08-29', 4, 12000.00);
INSERT INTO public.service_usage VALUES (2701, 1313, 5, '2025-08-28', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2702, 1314, 3, '2025-09-05', 1, 3500.00);
INSERT INTO public.service_usage VALUES (2703, 1314, 5, '2025-09-04', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2704, 1314, 6, '2025-09-04', 3, 600.00);
INSERT INTO public.service_usage VALUES (2705, 1315, 1, '2025-09-09', 3, 2500.00);
INSERT INTO public.service_usage VALUES (2706, 1315, 3, '2025-09-08', 1, 3500.00);
INSERT INTO public.service_usage VALUES (2707, 1315, 6, '2025-09-10', 3, 600.00);
INSERT INTO public.service_usage VALUES (2708, 1316, 2, '2025-09-13', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2709, 1316, 5, '2025-09-12', 1, 15000.00);
INSERT INTO public.service_usage VALUES (2710, 1316, 4, '2025-09-13', 3, 1800.00);
INSERT INTO public.service_usage VALUES (2711, 1316, 2, '2025-09-12', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2712, 1317, 3, '2025-09-18', 4, 3500.00);
INSERT INTO public.service_usage VALUES (2713, 1317, 3, '2025-09-19', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2714, 1317, 5, '2025-09-17', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2715, 1317, 7, '2025-09-19', 1, 12000.00);
INSERT INTO public.service_usage VALUES (2716, 1318, 5, '2025-09-22', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2717, 1319, 3, '2025-09-27', 2, 3500.00);
INSERT INTO public.service_usage VALUES (2718, 1320, 7, '2025-10-01', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2719, 1321, 6, '2025-07-04', 3, 600.00);
INSERT INTO public.service_usage VALUES (2720, 1322, 1, '2025-07-08', 4, 2500.00);
INSERT INTO public.service_usage VALUES (2721, 1322, 2, '2025-07-08', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2722, 1323, 3, '2025-07-12', 4, 3500.00);
INSERT INTO public.service_usage VALUES (2723, 1323, 3, '2025-07-12', 2, 3500.00);
INSERT INTO public.service_usage VALUES (2724, 1323, 1, '2025-07-12', 3, 2500.00);
INSERT INTO public.service_usage VALUES (2725, 1323, 7, '2025-07-11', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2726, 1324, 1, '2025-07-17', 2, 2500.00);
INSERT INTO public.service_usage VALUES (2727, 1325, 1, '2025-07-24', 2, 2500.00);
INSERT INTO public.service_usage VALUES (2728, 1326, 7, '2025-07-26', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2729, 1326, 7, '2025-07-27', 1, 12000.00);
INSERT INTO public.service_usage VALUES (2730, 1326, 3, '2025-07-28', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2731, 1328, 7, '2025-08-05', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2732, 1328, 1, '2025-08-05', 3, 2500.00);
INSERT INTO public.service_usage VALUES (2733, 1329, 5, '2025-08-07', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2734, 1329, 7, '2025-08-07', 4, 12000.00);
INSERT INTO public.service_usage VALUES (2735, 1329, 2, '2025-08-07', 1, 6000.00);
INSERT INTO public.service_usage VALUES (2736, 1330, 5, '2025-08-11', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2737, 1330, 6, '2025-08-12', 2, 600.00);
INSERT INTO public.service_usage VALUES (2738, 1330, 2, '2025-08-10', 2, 6000.00);
INSERT INTO public.service_usage VALUES (2739, 1330, 4, '2025-08-13', 4, 1800.00);
INSERT INTO public.service_usage VALUES (2740, 1331, 4, '2025-08-16', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2741, 1331, 1, '2025-08-17', 2, 2500.00);
INSERT INTO public.service_usage VALUES (2742, 1332, 7, '2025-08-22', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2743, 1332, 1, '2025-08-22', 4, 2500.00);
INSERT INTO public.service_usage VALUES (2744, 1332, 5, '2025-08-22', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2745, 1334, 4, '2025-08-30', 4, 1800.00);
INSERT INTO public.service_usage VALUES (2746, 1334, 7, '2025-08-30', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2747, 1334, 2, '2025-08-30', 2, 6000.00);
INSERT INTO public.service_usage VALUES (2748, 1335, 1, '2025-08-31', 2, 2500.00);
INSERT INTO public.service_usage VALUES (2749, 1335, 5, '2025-09-01', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2750, 1335, 4, '2025-08-31', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2751, 1336, 1, '2025-09-04', 1, 2500.00);
INSERT INTO public.service_usage VALUES (2752, 1336, 6, '2025-09-04', 4, 600.00);
INSERT INTO public.service_usage VALUES (2753, 1336, 5, '2025-09-05', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2754, 1336, 5, '2025-09-06', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2755, 1337, 2, '2025-09-08', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2756, 1338, 3, '2025-09-17', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2757, 1338, 4, '2025-09-16', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2758, 1338, 2, '2025-09-15', 4, 6000.00);
INSERT INTO public.service_usage VALUES (2759, 1338, 6, '2025-09-15', 4, 600.00);
INSERT INTO public.service_usage VALUES (2760, 1339, 1, '2025-09-18', 1, 2500.00);
INSERT INTO public.service_usage VALUES (2761, 1340, 4, '2025-09-23', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2762, 1341, 5, '2025-09-26', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2763, 1341, 3, '2025-09-27', 1, 3500.00);
INSERT INTO public.service_usage VALUES (2764, 1342, 7, '2025-10-01', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2765, 1342, 7, '2025-10-01', 1, 12000.00);
INSERT INTO public.service_usage VALUES (2766, 1343, 3, '2025-07-02', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2767, 1344, 5, '2025-07-05', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2768, 1344, 6, '2025-07-05', 2, 600.00);
INSERT INTO public.service_usage VALUES (2769, 1345, 6, '2025-07-12', 3, 600.00);
INSERT INTO public.service_usage VALUES (2770, 1345, 7, '2025-07-09', 4, 12000.00);
INSERT INTO public.service_usage VALUES (2771, 1346, 6, '2025-07-16', 3, 600.00);
INSERT INTO public.service_usage VALUES (2772, 1346, 4, '2025-07-14', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2773, 1346, 1, '2025-07-14', 3, 2500.00);
INSERT INTO public.service_usage VALUES (2774, 1346, 3, '2025-07-15', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2775, 1347, 5, '2025-07-17', 4, 15000.00);
INSERT INTO public.service_usage VALUES (2776, 1347, 5, '2025-07-17', 1, 15000.00);
INSERT INTO public.service_usage VALUES (2777, 1347, 2, '2025-07-17', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2778, 1347, 4, '2025-07-17', 3, 1800.00);
INSERT INTO public.service_usage VALUES (2779, 1350, 7, '2025-07-29', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2780, 1350, 7, '2025-08-01', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2781, 1351, 3, '2025-08-02', 2, 3500.00);
INSERT INTO public.service_usage VALUES (2782, 1351, 5, '2025-08-02', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2783, 1352, 2, '2025-08-05', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2784, 1352, 5, '2025-08-05', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2785, 1353, 5, '2025-08-11', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2786, 1354, 7, '2025-08-14', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2787, 1356, 1, '2025-08-25', 1, 2500.00);
INSERT INTO public.service_usage VALUES (2788, 1356, 4, '2025-08-23', 1, 1800.00);
INSERT INTO public.service_usage VALUES (2789, 1356, 3, '2025-08-25', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2790, 1357, 2, '2025-08-27', 4, 6000.00);
INSERT INTO public.service_usage VALUES (2791, 1357, 3, '2025-08-27', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2792, 1357, 7, '2025-08-27', 4, 12000.00);
INSERT INTO public.service_usage VALUES (2793, 1357, 6, '2025-08-28', 2, 600.00);
INSERT INTO public.service_usage VALUES (2794, 1358, 6, '2025-09-05', 3, 600.00);
INSERT INTO public.service_usage VALUES (2795, 1358, 3, '2025-09-04', 1, 3500.00);
INSERT INTO public.service_usage VALUES (2796, 1358, 3, '2025-09-03', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2797, 1358, 2, '2025-09-04', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2798, 1360, 5, '2025-09-14', 4, 15000.00);
INSERT INTO public.service_usage VALUES (2799, 1360, 3, '2025-09-15', 4, 3500.00);
INSERT INTO public.service_usage VALUES (2800, 1360, 5, '2025-09-15', 1, 15000.00);
INSERT INTO public.service_usage VALUES (2801, 1360, 1, '2025-09-15', 2, 2500.00);
INSERT INTO public.service_usage VALUES (2802, 1361, 6, '2025-09-19', 3, 600.00);
INSERT INTO public.service_usage VALUES (2803, 1361, 1, '2025-09-17', 3, 2500.00);
INSERT INTO public.service_usage VALUES (2804, 1361, 1, '2025-09-18', 3, 2500.00);
INSERT INTO public.service_usage VALUES (2805, 1361, 5, '2025-09-19', 4, 15000.00);
INSERT INTO public.service_usage VALUES (2806, 1362, 6, '2025-09-23', 2, 600.00);
INSERT INTO public.service_usage VALUES (2807, 1362, 3, '2025-09-22', 4, 3500.00);
INSERT INTO public.service_usage VALUES (2808, 1362, 4, '2025-09-23', 1, 1800.00);
INSERT INTO public.service_usage VALUES (2809, 1363, 7, '2025-09-25', 4, 12000.00);
INSERT INTO public.service_usage VALUES (2810, 1363, 3, '2025-09-28', 1, 3500.00);
INSERT INTO public.service_usage VALUES (2811, 1363, 5, '2025-09-25', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2812, 1366, 2, '2025-07-06', 2, 6000.00);
INSERT INTO public.service_usage VALUES (2813, 1367, 6, '2025-07-12', 2, 600.00);
INSERT INTO public.service_usage VALUES (2814, 1367, 7, '2025-07-12', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2815, 1367, 1, '2025-07-12', 1, 2500.00);
INSERT INTO public.service_usage VALUES (2816, 1368, 5, '2025-07-13', 4, 15000.00);
INSERT INTO public.service_usage VALUES (2817, 1368, 6, '2025-07-14', 3, 600.00);
INSERT INTO public.service_usage VALUES (2818, 1370, 2, '2025-07-22', 4, 6000.00);
INSERT INTO public.service_usage VALUES (2819, 1370, 2, '2025-07-24', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2820, 1370, 6, '2025-07-23', 2, 600.00);
INSERT INTO public.service_usage VALUES (2821, 1371, 5, '2025-07-27', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2822, 1372, 1, '2025-08-01', 4, 2500.00);
INSERT INTO public.service_usage VALUES (2823, 1372, 3, '2025-08-01', 1, 3500.00);
INSERT INTO public.service_usage VALUES (2824, 1372, 2, '2025-08-01', 4, 6000.00);
INSERT INTO public.service_usage VALUES (2825, 1375, 4, '2025-08-10', 3, 1800.00);
INSERT INTO public.service_usage VALUES (2826, 1376, 1, '2025-08-16', 3, 2500.00);
INSERT INTO public.service_usage VALUES (2827, 1376, 4, '2025-08-16', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2828, 1376, 1, '2025-08-16', 1, 2500.00);
INSERT INTO public.service_usage VALUES (2829, 1376, 6, '2025-08-15', 4, 600.00);
INSERT INTO public.service_usage VALUES (2830, 1377, 7, '2025-08-20', 2, 12000.00);
INSERT INTO public.service_usage VALUES (2831, 1377, 7, '2025-08-19', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2832, 1377, 2, '2025-08-19', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2833, 1377, 3, '2025-08-18', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2834, 1378, 5, '2025-08-22', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2835, 1378, 7, '2025-08-23', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2836, 1378, 5, '2025-08-24', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2837, 1379, 7, '2025-08-28', 4, 12000.00);
INSERT INTO public.service_usage VALUES (2838, 1379, 4, '2025-08-27', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2839, 1380, 6, '2025-09-02', 2, 600.00);
INSERT INTO public.service_usage VALUES (2840, 1380, 6, '2025-09-01', 2, 600.00);
INSERT INTO public.service_usage VALUES (2841, 1380, 2, '2025-09-02', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2842, 1380, 1, '2025-09-02', 3, 2500.00);
INSERT INTO public.service_usage VALUES (2843, 1381, 5, '2025-09-09', 3, 15000.00);
INSERT INTO public.service_usage VALUES (2844, 1384, 2, '2025-09-24', 4, 6000.00);
INSERT INTO public.service_usage VALUES (2845, 1385, 1, '2025-09-27', 2, 2500.00);
INSERT INTO public.service_usage VALUES (2846, 1385, 5, '2025-09-27', 1, 15000.00);
INSERT INTO public.service_usage VALUES (2847, 1385, 6, '2025-09-27', 2, 600.00);
INSERT INTO public.service_usage VALUES (2848, 1386, 4, '2025-09-30', 3, 1800.00);
INSERT INTO public.service_usage VALUES (2849, 1386, 7, '2025-09-30', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2850, 1386, 1, '2025-09-30', 1, 2500.00);
INSERT INTO public.service_usage VALUES (2851, 1387, 4, '2025-07-02', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2852, 1387, 4, '2025-07-02', 3, 1800.00);
INSERT INTO public.service_usage VALUES (2853, 1387, 3, '2025-07-03', 2, 3500.00);
INSERT INTO public.service_usage VALUES (2854, 1387, 3, '2025-07-01', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2855, 1389, 1, '2025-07-10', 4, 2500.00);
INSERT INTO public.service_usage VALUES (2856, 1389, 5, '2025-07-11', 1, 15000.00);
INSERT INTO public.service_usage VALUES (2857, 1389, 3, '2025-07-11', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2858, 1391, 1, '2025-07-19', 1, 2500.00);
INSERT INTO public.service_usage VALUES (2859, 1391, 6, '2025-07-18', 1, 600.00);
INSERT INTO public.service_usage VALUES (2860, 1392, 2, '2025-07-24', 1, 6000.00);
INSERT INTO public.service_usage VALUES (2861, 1392, 2, '2025-07-22', 2, 6000.00);
INSERT INTO public.service_usage VALUES (2862, 1393, 3, '2025-07-30', 2, 3500.00);
INSERT INTO public.service_usage VALUES (2863, 1393, 4, '2025-07-28', 1, 1800.00);
INSERT INTO public.service_usage VALUES (2864, 1393, 6, '2025-07-28', 4, 600.00);
INSERT INTO public.service_usage VALUES (2865, 1395, 4, '2025-08-04', 3, 1800.00);
INSERT INTO public.service_usage VALUES (2866, 1396, 6, '2025-08-08', 3, 600.00);
INSERT INTO public.service_usage VALUES (2867, 1396, 2, '2025-08-07', 1, 6000.00);
INSERT INTO public.service_usage VALUES (2868, 1396, 6, '2025-08-08', 4, 600.00);
INSERT INTO public.service_usage VALUES (2869, 1396, 1, '2025-08-09', 1, 2500.00);
INSERT INTO public.service_usage VALUES (2870, 1397, 3, '2025-08-12', 4, 3500.00);
INSERT INTO public.service_usage VALUES (2871, 1397, 2, '2025-08-13', 2, 6000.00);
INSERT INTO public.service_usage VALUES (2872, 1397, 2, '2025-08-12', 1, 6000.00);
INSERT INTO public.service_usage VALUES (2873, 1397, 1, '2025-08-13', 3, 2500.00);
INSERT INTO public.service_usage VALUES (2874, 1398, 1, '2025-08-17', 3, 2500.00);
INSERT INTO public.service_usage VALUES (2875, 1398, 7, '2025-08-15', 1, 12000.00);
INSERT INTO public.service_usage VALUES (2876, 1398, 1, '2025-08-17', 2, 2500.00);
INSERT INTO public.service_usage VALUES (2877, 1398, 3, '2025-08-17', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2878, 1399, 6, '2025-08-21', 1, 600.00);
INSERT INTO public.service_usage VALUES (2879, 1399, 2, '2025-08-21', 1, 6000.00);
INSERT INTO public.service_usage VALUES (2880, 1400, 2, '2025-08-24', 4, 6000.00);
INSERT INTO public.service_usage VALUES (2881, 1400, 1, '2025-08-25', 3, 2500.00);
INSERT INTO public.service_usage VALUES (2882, 1400, 6, '2025-08-25', 3, 600.00);
INSERT INTO public.service_usage VALUES (2883, 1400, 7, '2025-08-25', 3, 12000.00);
INSERT INTO public.service_usage VALUES (2884, 1401, 4, '2025-08-29', 3, 1800.00);
INSERT INTO public.service_usage VALUES (2885, 1401, 1, '2025-08-29', 4, 2500.00);
INSERT INTO public.service_usage VALUES (2886, 1402, 4, '2025-09-03', 4, 1800.00);
INSERT INTO public.service_usage VALUES (2887, 1402, 4, '2025-09-01', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2888, 1404, 2, '2025-09-10', 2, 6000.00);
INSERT INTO public.service_usage VALUES (2889, 1404, 3, '2025-09-08', 2, 3500.00);
INSERT INTO public.service_usage VALUES (2890, 1404, 3, '2025-09-08', 4, 3500.00);
INSERT INTO public.service_usage VALUES (2891, 1405, 3, '2025-09-13', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2892, 1405, 6, '2025-09-13', 1, 600.00);
INSERT INTO public.service_usage VALUES (2893, 1405, 5, '2025-09-13', 1, 15000.00);
INSERT INTO public.service_usage VALUES (2894, 1406, 1, '2025-09-17', 2, 2500.00);
INSERT INTO public.service_usage VALUES (2895, 1407, 3, '2025-09-21', 3, 3500.00);
INSERT INTO public.service_usage VALUES (2896, 1407, 5, '2025-09-21', 1, 15000.00);
INSERT INTO public.service_usage VALUES (2897, 1407, 2, '2025-09-21', 1, 6000.00);
INSERT INTO public.service_usage VALUES (2898, 1408, 5, '2025-09-24', 2, 15000.00);
INSERT INTO public.service_usage VALUES (2899, 1408, 4, '2025-09-24', 2, 1800.00);
INSERT INTO public.service_usage VALUES (2900, 1408, 5, '2025-09-24', 4, 15000.00);
INSERT INTO public.service_usage VALUES (2901, 1409, 6, '2025-09-28', 4, 600.00);
INSERT INTO public.service_usage VALUES (2902, 1409, 3, '2025-09-27', 1, 3500.00);
INSERT INTO public.service_usage VALUES (2903, 1410, 2, '2025-09-30', 4, 6000.00);
INSERT INTO public.service_usage VALUES (2904, 1441, 2, '2025-10-07', 3, 6000.00);
INSERT INTO public.service_usage VALUES (2905, 1441, 2, '2025-10-08', 1, 2500.00);
INSERT INTO public.service_usage VALUES (2906, 1441, 2, '2025-11-11', 2, 1500.00);
INSERT INTO public.service_usage VALUES (2907, 1449, 1, '2025-11-11', 1, 1500.00);
INSERT INTO public.service_usage VALUES (2908, 1449, 1, '2025-11-11', 1, 1500.00);
INSERT INTO public.service_usage VALUES (2909, 1449, 1, '2025-11-11', 1, 2500.00);


--
-- TOC entry 5403 (class 0 OID 16495)
-- Dependencies: 231
-- Data for Name: user_account; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.user_account VALUES (5, 'ishara.wickramasinghe1', '$2a$10$dummypassforcust', 'Customer', NULL);
INSERT INTO public.user_account VALUES (6, 'nuwan.peiris7', '$2a$10$dummypassforcust', 'Customer', NULL);
INSERT INTO public.user_account VALUES (7, 'ayesha.bandara14', '$2a$10$dummypassforcust', 'Customer', NULL);
INSERT INTO public.user_account VALUES (8, 'kasun.jayasinghe27', '$2a$10$dummypassforcust', 'Customer', NULL);
INSERT INTO public.user_account VALUES (9, 'roshan.peiris33', '$2a$10$dummypassforcust', 'Customer', NULL);
INSERT INTO public.user_account VALUES (10, 'kavindu.wijesinghe37', '$2a$10$dummypassforcust', 'Customer', NULL);
INSERT INTO public.user_account VALUES (11, 'kavindu.ranasinghe39', '$2a$10$dummypassforcust', 'Customer', NULL);
INSERT INTO public.user_account VALUES (12, 'supun.fernando40', '$2a$10$dummypassforcust', 'Customer', NULL);
INSERT INTO public.user_account VALUES (13, 'hasini.karunaratne52', '$2a$10$dummypassforcust', 'Customer', NULL);
INSERT INTO public.user_account VALUES (14, 'ishara.weerasinghe56', '$2a$10$dummypassforcust', 'Customer', NULL);
INSERT INTO public.user_account VALUES (15, 'maneesha.fernando57', '$2a$10$dummypassforcust', 'Customer', NULL);
INSERT INTO public.user_account VALUES (16, 'shenal.gunasekara65', '$2a$10$dummypassforcust', 'Customer', NULL);
INSERT INTO public.user_account VALUES (17, 'ishani.jayasinghe72', '$2a$10$dummypassforcust', 'Customer', NULL);
INSERT INTO public.user_account VALUES (18, 'dulani.abeysekera76', '$2a$10$dummypassforcust', 'Customer', NULL);
INSERT INTO public.user_account VALUES (19, 'dulani.gunasekara82', '$2a$10$dummypassforcust', 'Customer', NULL);
INSERT INTO public.user_account VALUES (20, 'ishani.ranasinghe83', '$2a$10$dummypassforcust', 'Customer', NULL);
INSERT INTO public.user_account VALUES (21, 'shenal.gunasekara95', '$2a$10$dummypassforcust', 'Customer', NULL);
INSERT INTO public.user_account VALUES (22, 'ishani.peiris97', '$2a$10$dummypassforcust', 'Customer', NULL);
INSERT INTO public.user_account VALUES (23, 'pramudi.karunaratne104', '$2a$10$dummypassforcust', 'Customer', NULL);
INSERT INTO public.user_account VALUES (24, 'kavindu.fernando106', '$2a$10$dummypassforcust', 'Customer', NULL);
INSERT INTO public.user_account VALUES (25, 'tharindu.fernando111', '$2a$10$dummypassforcust', 'Customer', NULL);
INSERT INTO public.user_account VALUES (26, 'lakmini.perera116', '$2a$10$dummypassforcust', 'Customer', NULL);
INSERT INTO public.user_account VALUES (27, 'lakmini.peiris118', '$2a$10$dummypassforcust', 'Customer', NULL);
INSERT INTO public.user_account VALUES (28, 'dulani.wickramasinghe132', '$2a$10$dummypassforcust', 'Customer', NULL);
INSERT INTO public.user_account VALUES (29, 'ishani.wijesinghe139', '$2a$10$dummypassforcust', 'Customer', NULL);
INSERT INTO public.user_account VALUES (43, 'manager_kandy', '$2a$10$dummyhash', 'Manager', NULL);
INSERT INTO public.user_account VALUES (44, 'manager_galle', '$2a$10$dummyhash', 'Manager', NULL);
INSERT INTO public.user_account VALUES (46, 'recept_kandy', '$2a$10$dummyhash', 'Receptionist', NULL);
INSERT INTO public.user_account VALUES (47, 'recept_galle', '$2a$10$dummyhash', 'Receptionist', NULL);
INSERT INTO public.user_account VALUES (48, 'accountant_colombo', '$2a$10$dummyhash', 'Accountant', NULL);
INSERT INTO public.user_account VALUES (49, 'accountant_kandy', '$2a$10$dummyhash', 'Accountant', NULL);
INSERT INTO public.user_account VALUES (50, 'accountant_galle', '$2a$10$dummyhash', 'Accountant', NULL);
INSERT INTO public.user_account VALUES (42, 'manager_colombo', '$2b$10$EP2f7QKggEk9tQDY0RbHou3Vu0GlbrKSwQfuwRXQIl5SXG4p57nVK', 'Manager', NULL);
INSERT INTO public.user_account VALUES (45, 'recept_colombo', '$2b$12$z4re42swc0WxMpL/dmCtveRDo5ew0u4Wzc3pW/oNjcJri0tJVFE8S', 'Receptionist', NULL);
INSERT INTO public.user_account VALUES (41, 'admin', '$2b$10$TlQLUyAbYGh6u6DZY5qLe.dRGTqHgvuVbvgkzILHLfGHDpP/6TVmW', 'Admin', NULL);


--
-- TOC entry 5442 (class 0 OID 0)
-- Dependencies: 248
-- Name: audit_log_audit_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.audit_log_audit_id_seq', 101, true);


--
-- TOC entry 5443 (class 0 OID 0)
-- Dependencies: 238
-- Name: booking_booking_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.booking_booking_id_seq', 1464, true);


--
-- TOC entry 5444 (class 0 OID 0)
-- Dependencies: 218
-- Name: branch_branch_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.branch_branch_id_seq', 3, true);


--
-- TOC entry 5445 (class 0 OID 0)
-- Dependencies: 234
-- Name: customer_customer_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.customer_customer_id_seq', 25, true);


--
-- TOC entry 5446 (class 0 OID 0)
-- Dependencies: 232
-- Name: employee_employee_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.employee_employee_id_seq', 15, true);


--
-- TOC entry 5447 (class 0 OID 0)
-- Dependencies: 228
-- Name: guest_guest_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.guest_guest_id_seq', 151, true);


--
-- TOC entry 5448 (class 0 OID 0)
-- Dependencies: 220
-- Name: invoice_invoice_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.invoice_invoice_id_seq', 1, false);


--
-- TOC entry 5449 (class 0 OID 0)
-- Dependencies: 251
-- Name: payment_adjustment_adjustment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.payment_adjustment_adjustment_id_seq', 14, true);


--
-- TOC entry 5450 (class 0 OID 0)
-- Dependencies: 222
-- Name: payment_payment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.payment_payment_id_seq', 1671, true);


--
-- TOC entry 5451 (class 0 OID 0)
-- Dependencies: 236
-- Name: pre_booking_pre_booking_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pre_booking_pre_booking_id_seq', 6, true);


--
-- TOC entry 5452 (class 0 OID 0)
-- Dependencies: 224
-- Name: room_room_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.room_room_id_seq', 60, true);


--
-- TOC entry 5453 (class 0 OID 0)
-- Dependencies: 226
-- Name: room_type_room_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.room_type_room_type_id_seq', 4, true);


--
-- TOC entry 5454 (class 0 OID 0)
-- Dependencies: 240
-- Name: service_catalog_service_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.service_catalog_service_id_seq', 7, true);


--
-- TOC entry 5455 (class 0 OID 0)
-- Dependencies: 242
-- Name: service_usage_service_usage_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.service_usage_service_usage_id_seq', 2909, true);


--
-- TOC entry 5456 (class 0 OID 0)
-- Dependencies: 230
-- Name: user_account_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_account_user_id_seq', 51, true);


--
-- TOC entry 5215 (class 2606 OID 17786)
-- Name: audit_log audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (audit_id);


--
-- TOC entry 5204 (class 2606 OID 16547)
-- Name: booking booking_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.booking
    ADD CONSTRAINT booking_pkey PRIMARY KEY (booking_id);


--
-- TOC entry 5162 (class 2606 OID 16398)
-- Name: branch branch_branch_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.branch
    ADD CONSTRAINT branch_branch_name_key UNIQUE (branch_name);


--
-- TOC entry 5164 (class 2606 OID 16396)
-- Name: branch branch_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.branch
    ADD CONSTRAINT branch_pkey PRIMARY KEY (branch_id);


--
-- TOC entry 5195 (class 2606 OID 16529)
-- Name: customer customer_guest_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer
    ADD CONSTRAINT customer_guest_id_key UNIQUE (guest_id);


--
-- TOC entry 5197 (class 2606 OID 16525)
-- Name: customer customer_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer
    ADD CONSTRAINT customer_pkey PRIMARY KEY (customer_id);


--
-- TOC entry 5199 (class 2606 OID 16527)
-- Name: customer customer_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer
    ADD CONSTRAINT customer_user_id_key UNIQUE (user_id);


--
-- TOC entry 5189 (class 2606 OID 16517)
-- Name: employee employee_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_email_key UNIQUE (email);


--
-- TOC entry 5191 (class 2606 OID 16513)
-- Name: employee employee_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_pkey PRIMARY KEY (employee_id);


--
-- TOC entry 5193 (class 2606 OID 16515)
-- Name: employee employee_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_user_id_key UNIQUE (user_id);


--
-- TOC entry 5179 (class 2606 OID 16493)
-- Name: guest guest_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.guest
    ADD CONSTRAINT guest_email_key UNIQUE (email);


--
-- TOC entry 5181 (class 2606 OID 16491)
-- Name: guest guest_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.guest
    ADD CONSTRAINT guest_pkey PRIMARY KEY (guest_id);


--
-- TOC entry 5167 (class 2606 OID 16454)
-- Name: invoice invoice_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoice
    ADD CONSTRAINT invoice_pkey PRIMARY KEY (invoice_id);


--
-- TOC entry 5207 (class 2606 OID 17304)
-- Name: booking no_overlapping_bookings; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.booking
    ADD CONSTRAINT no_overlapping_bookings EXCLUDE USING gist (room_id WITH =, daterange(check_in_date, check_out_date, '[)'::text) WITH &&) WHERE ((status = ANY (ARRAY['Booked'::public.booking_status, 'Checked-In'::public.booking_status]))) DEFERRABLE;


--
-- TOC entry 5218 (class 2606 OID 17821)
-- Name: payment_adjustment payment_adjustment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment_adjustment
    ADD CONSTRAINT payment_adjustment_pkey PRIMARY KEY (adjustment_id);


--
-- TOC entry 5170 (class 2606 OID 16462)
-- Name: payment payment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_pkey PRIMARY KEY (payment_id);


--
-- TOC entry 5202 (class 2606 OID 16536)
-- Name: pre_booking pre_booking_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pre_booking
    ADD CONSTRAINT pre_booking_pkey PRIMARY KEY (pre_booking_id);


--
-- TOC entry 5173 (class 2606 OID 16470)
-- Name: room room_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.room
    ADD CONSTRAINT room_pkey PRIMARY KEY (room_id);


--
-- TOC entry 5175 (class 2606 OID 16482)
-- Name: room_type room_type_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.room_type
    ADD CONSTRAINT room_type_name_key UNIQUE (name);


--
-- TOC entry 5177 (class 2606 OID 16480)
-- Name: room_type room_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.room_type
    ADD CONSTRAINT room_type_pkey PRIMARY KEY (room_type_id);


--
-- TOC entry 5209 (class 2606 OID 16558)
-- Name: service_catalog service_catalog_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_catalog
    ADD CONSTRAINT service_catalog_code_key UNIQUE (code);


--
-- TOC entry 5211 (class 2606 OID 16556)
-- Name: service_catalog service_catalog_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_catalog
    ADD CONSTRAINT service_catalog_pkey PRIMARY KEY (service_id);


--
-- TOC entry 5213 (class 2606 OID 16566)
-- Name: service_usage service_usage_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_usage
    ADD CONSTRAINT service_usage_pkey PRIMARY KEY (service_usage_id);


--
-- TOC entry 5183 (class 2606 OID 16506)
-- Name: user_account user_account_guest_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_account
    ADD CONSTRAINT user_account_guest_id_key UNIQUE (guest_id);


--
-- TOC entry 5185 (class 2606 OID 16502)
-- Name: user_account user_account_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_account
    ADD CONSTRAINT user_account_pkey PRIMARY KEY (user_id);


--
-- TOC entry 5187 (class 2606 OID 16504)
-- Name: user_account user_account_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_account
    ADD CONSTRAINT user_account_username_key UNIQUE (username);


--
-- TOC entry 5216 (class 1259 OID 17827)
-- Name: idx_adjust_booking; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_adjust_booking ON public.payment_adjustment USING btree (booking_id);


--
-- TOC entry 5205 (class 1259 OID 17860)
-- Name: idx_booking_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_booking_created_at ON public.booking USING btree (created_at);


--
-- TOC entry 5200 (class 1259 OID 17859)
-- Name: idx_pre_booking_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pre_booking_created_at ON public.pre_booking USING btree (created_at);


--
-- TOC entry 5168 (class 1259 OID 16471)
-- Name: payment_paidat_ix; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX payment_paidat_ix ON public.payment USING btree (paid_at);


--
-- TOC entry 5171 (class 1259 OID 17866)
-- Name: uq_booking_payment_ref; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_booking_payment_ref ON public.payment USING btree (booking_id, payment_reference);


--
-- TOC entry 5165 (class 1259 OID 17787)
-- Name: uq_branch_code; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_branch_code ON public.branch USING btree (branch_code);


--
-- TOC entry 5237 (class 2620 OID 17855)
-- Name: booking booking_min_advance_guard; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER booking_min_advance_guard BEFORE INSERT OR UPDATE OF check_in_date, check_out_date, booked_rate, advance_payment ON public.booking FOR EACH ROW EXECUTE FUNCTION public.trg_check_min_advance();


--
-- TOC entry 5238 (class 2620 OID 17843)
-- Name: booking refund_advance_on_cancel; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER refund_advance_on_cancel AFTER UPDATE OF status ON public.booking FOR EACH ROW EXECUTE FUNCTION public.trg_refund_advance_on_cancel();


--
-- TOC entry 5239 (class 2620 OID 17845)
-- Name: booking refund_advance_policy; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER refund_advance_policy AFTER UPDATE OF status ON public.booking FOR EACH ROW EXECUTE FUNCTION public.trg_refund_advance_policy();


--
-- TOC entry 5231 (class 2606 OID 16623)
-- Name: booking fk_book_guest; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.booking
    ADD CONSTRAINT fk_book_guest FOREIGN KEY (guest_id) REFERENCES public.guest(guest_id);


--
-- TOC entry 5232 (class 2606 OID 16618)
-- Name: booking fk_book_pre; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.booking
    ADD CONSTRAINT fk_book_pre FOREIGN KEY (pre_booking_id) REFERENCES public.pre_booking(pre_booking_id);


--
-- TOC entry 5233 (class 2606 OID 16628)
-- Name: booking fk_book_room; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.booking
    ADD CONSTRAINT fk_book_room FOREIGN KEY (room_id) REFERENCES public.room(room_id);


--
-- TOC entry 5226 (class 2606 OID 16598)
-- Name: customer fk_cust_guest; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer
    ADD CONSTRAINT fk_cust_guest FOREIGN KEY (guest_id) REFERENCES public.guest(guest_id);


--
-- TOC entry 5227 (class 2606 OID 16593)
-- Name: customer fk_cust_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer
    ADD CONSTRAINT fk_cust_user FOREIGN KEY (user_id) REFERENCES public.user_account(user_id);


--
-- TOC entry 5224 (class 2606 OID 16588)
-- Name: employee fk_emp_branch; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT fk_emp_branch FOREIGN KEY (branch_id) REFERENCES public.branch(branch_id);


--
-- TOC entry 5225 (class 2606 OID 16583)
-- Name: employee fk_emp_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT fk_emp_user FOREIGN KEY (user_id) REFERENCES public.user_account(user_id);


--
-- TOC entry 5219 (class 2606 OID 16648)
-- Name: invoice fk_inv_book; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoice
    ADD CONSTRAINT fk_inv_book FOREIGN KEY (booking_id) REFERENCES public.booking(booking_id);


--
-- TOC entry 5220 (class 2606 OID 16643)
-- Name: payment fk_pay_book; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT fk_pay_book FOREIGN KEY (booking_id) REFERENCES public.booking(booking_id);


--
-- TOC entry 5228 (class 2606 OID 16613)
-- Name: pre_booking fk_pre_creator; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pre_booking
    ADD CONSTRAINT fk_pre_creator FOREIGN KEY (created_by_employee_id) REFERENCES public.employee(employee_id);


--
-- TOC entry 5229 (class 2606 OID 16603)
-- Name: pre_booking fk_pre_guest; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pre_booking
    ADD CONSTRAINT fk_pre_guest FOREIGN KEY (guest_id) REFERENCES public.guest(guest_id);


--
-- TOC entry 5230 (class 2606 OID 16608)
-- Name: pre_booking fk_pre_room; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pre_booking
    ADD CONSTRAINT fk_pre_room FOREIGN KEY (room_id) REFERENCES public.room(room_id);


--
-- TOC entry 5221 (class 2606 OID 16568)
-- Name: room fk_room_branch; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.room
    ADD CONSTRAINT fk_room_branch FOREIGN KEY (branch_id) REFERENCES public.branch(branch_id);


--
-- TOC entry 5222 (class 2606 OID 16573)
-- Name: room fk_room_type; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.room
    ADD CONSTRAINT fk_room_type FOREIGN KEY (room_type_id) REFERENCES public.room_type(room_type_id);


--
-- TOC entry 5234 (class 2606 OID 16633)
-- Name: service_usage fk_usage_book; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_usage
    ADD CONSTRAINT fk_usage_book FOREIGN KEY (booking_id) REFERENCES public.booking(booking_id);


--
-- TOC entry 5235 (class 2606 OID 16638)
-- Name: service_usage fk_usage_serv; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_usage
    ADD CONSTRAINT fk_usage_serv FOREIGN KEY (service_id) REFERENCES public.service_catalog(service_id);


--
-- TOC entry 5223 (class 2606 OID 16578)
-- Name: user_account fk_user_guest; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_account
    ADD CONSTRAINT fk_user_guest FOREIGN KEY (guest_id) REFERENCES public.guest(guest_id);


--
-- TOC entry 5236 (class 2606 OID 17822)
-- Name: payment_adjustment payment_adjustment_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment_adjustment
    ADD CONSTRAINT payment_adjustment_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.booking(booking_id) ON DELETE CASCADE;


-- Completed on 2025-10-07 20:48:42

--
-- PostgreSQL database dump complete
--

\unrestrict DP1rxBdRWDSruhnnJ251IdPsyVMNYcKxPlWT6wVFC4BQDOMwAAnff9cOzVJUEzG

