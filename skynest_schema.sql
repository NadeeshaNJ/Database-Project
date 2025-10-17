--
-- PostgreSQL database dump
--

\restrict Qy1DrmI3OE1bo6KS02qsf7FF3YtkAjj6SCuoRvfiFOPZz61Pezqs6hYYXfPCJh6

-- Dumped from database version 18.0
-- Dumped by pg_dump version 18.0

-- Started on 2025-10-18 02:49:51

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
-- TOC entry 2 (class 3079 OID 16390)
-- Name: btree_gist; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS btree_gist WITH SCHEMA public;


--
-- TOC entry 5565 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION btree_gist; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION btree_gist IS 'support for indexing common datatypes in GiST';


--
-- TOC entry 1123 (class 1247 OID 17117)
-- Name: adjustment_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.adjustment_type AS ENUM (
    'refund',
    'chargeback',
    'manual_adjustment'
);


ALTER TYPE public.adjustment_type OWNER TO postgres;

--
-- TOC entry 1126 (class 1247 OID 17124)
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
-- TOC entry 1129 (class 1247 OID 17134)
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
-- TOC entry 1132 (class 1247 OID 17144)
-- Name: prebooking_method; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.prebooking_method AS ENUM (
    'Online',
    'Phone',
    'Walk-in'
);


ALTER TYPE public.prebooking_method OWNER TO postgres;

--
-- TOC entry 1135 (class 1247 OID 17152)
-- Name: room_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.room_status AS ENUM (
    'Available',
    'Occupied',
    'Maintenance'
);


ALTER TYPE public.room_status OWNER TO postgres;

--
-- TOC entry 1138 (class 1247 OID 17160)
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
-- TOC entry 420 (class 1255 OID 17171)
-- Name: fn_balance_due(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_balance_due(p bigint) RETURNS numeric
    LANGUAGE sql STABLE
    AS $$
   SELECT ROUND(COALESCE(fn_bill_total(p),0) - COALESCE(fn_total_paid(p),0), 2);
$$;


ALTER FUNCTION public.fn_balance_due(p bigint) OWNER TO postgres;

--
-- TOC entry 255 (class 1255 OID 17172)
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
-- TOC entry 366 (class 1255 OID 17173)
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
-- TOC entry 376 (class 1255 OID 17174)
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
-- TOC entry 432 (class 1255 OID 17175)
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
-- TOC entry 284 (class 1255 OID 17176)
-- Name: fn_total_paid(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_total_paid(p_booking_id bigint) RETURNS numeric
    LANGUAGE sql STABLE
    AS $$
  SELECT COALESCE(SUM(p.amount),0) FROM payment p WHERE p.booking_id = p_booking_id;
$$;


ALTER FUNCTION public.fn_total_paid(p_booking_id bigint) OWNER TO postgres;

--
-- TOC entry 285 (class 1255 OID 17177)
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
-- TOC entry 471 (class 1255 OID 17178)
-- Name: randn(numeric); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.randn(p numeric) RETURNS numeric
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT (random() * p)::numeric;
$$;


ALTER FUNCTION public.randn(p numeric) OWNER TO postgres;

--
-- TOC entry 436 (class 1255 OID 17179)
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
-- TOC entry 298 (class 1255 OID 17180)
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
-- TOC entry 472 (class 1255 OID 17181)
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
-- TOC entry 364 (class 1255 OID 17182)
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
-- TOC entry 220 (class 1259 OID 17183)
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
-- TOC entry 221 (class 1259 OID 17193)
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
-- TOC entry 5566 (class 0 OID 0)
-- Dependencies: 221
-- Name: audit_log_audit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.audit_log_audit_id_seq OWNED BY public.audit_log.audit_id;


--
-- TOC entry 222 (class 1259 OID 17194)
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
-- TOC entry 223 (class 1259 OID 17216)
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
-- TOC entry 5567 (class 0 OID 0)
-- Dependencies: 223
-- Name: booking_booking_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.booking_booking_id_seq OWNED BY public.booking.booking_id;


--
-- TOC entry 224 (class 1259 OID 17217)
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
-- TOC entry 225 (class 1259 OID 17224)
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
-- TOC entry 5568 (class 0 OID 0)
-- Dependencies: 225
-- Name: branch_branch_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.branch_branch_id_seq OWNED BY public.branch.branch_id;


--
-- TOC entry 226 (class 1259 OID 17225)
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
-- TOC entry 227 (class 1259 OID 17231)
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
-- TOC entry 5569 (class 0 OID 0)
-- Dependencies: 227
-- Name: customer_customer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.customer_customer_id_seq OWNED BY public.customer.customer_id;


--
-- TOC entry 228 (class 1259 OID 17232)
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
-- TOC entry 229 (class 1259 OID 17239)
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
-- TOC entry 5570 (class 0 OID 0)
-- Dependencies: 229
-- Name: employee_employee_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.employee_employee_id_seq OWNED BY public.employee.employee_id;


--
-- TOC entry 230 (class 1259 OID 17240)
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
-- TOC entry 231 (class 1259 OID 17247)
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
-- TOC entry 5571 (class 0 OID 0)
-- Dependencies: 231
-- Name: guest_guest_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.guest_guest_id_seq OWNED BY public.guest.guest_id;


--
-- TOC entry 232 (class 1259 OID 17248)
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
-- TOC entry 233 (class 1259 OID 17255)
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
-- TOC entry 5572 (class 0 OID 0)
-- Dependencies: 233
-- Name: invoice_invoice_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.invoice_invoice_id_seq OWNED BY public.invoice.invoice_id;


--
-- TOC entry 234 (class 1259 OID 17256)
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
-- TOC entry 235 (class 1259 OID 17264)
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
-- TOC entry 236 (class 1259 OID 17274)
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
-- TOC entry 5573 (class 0 OID 0)
-- Dependencies: 236
-- Name: payment_adjustment_adjustment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.payment_adjustment_adjustment_id_seq OWNED BY public.payment_adjustment.adjustment_id;


--
-- TOC entry 237 (class 1259 OID 17275)
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
-- TOC entry 5574 (class 0 OID 0)
-- Dependencies: 237
-- Name: payment_payment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.payment_payment_id_seq OWNED BY public.payment.payment_id;


--
-- TOC entry 238 (class 1259 OID 17276)
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
-- TOC entry 239 (class 1259 OID 17287)
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
-- TOC entry 5575 (class 0 OID 0)
-- Dependencies: 239
-- Name: pre_booking_pre_booking_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pre_booking_pre_booking_id_seq OWNED BY public.pre_booking.pre_booking_id;


--
-- TOC entry 240 (class 1259 OID 17288)
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
-- TOC entry 241 (class 1259 OID 17297)
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
-- TOC entry 5576 (class 0 OID 0)
-- Dependencies: 241
-- Name: room_room_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.room_room_id_seq OWNED BY public.room.room_id;


--
-- TOC entry 242 (class 1259 OID 17298)
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
-- TOC entry 243 (class 1259 OID 17307)
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
-- TOC entry 5577 (class 0 OID 0)
-- Dependencies: 243
-- Name: room_type_room_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.room_type_room_type_id_seq OWNED BY public.room_type.room_type_id;


--
-- TOC entry 244 (class 1259 OID 17308)
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
-- TOC entry 245 (class 1259 OID 17318)
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
-- TOC entry 5578 (class 0 OID 0)
-- Dependencies: 245
-- Name: service_catalog_service_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.service_catalog_service_id_seq OWNED BY public.service_catalog.service_id;


--
-- TOC entry 246 (class 1259 OID 17319)
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
-- TOC entry 247 (class 1259 OID 17329)
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
-- TOC entry 5579 (class 0 OID 0)
-- Dependencies: 247
-- Name: service_usage_service_usage_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.service_usage_service_usage_id_seq OWNED BY public.service_usage.service_usage_id;


--
-- TOC entry 248 (class 1259 OID 17330)
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
-- TOC entry 249 (class 1259 OID 17337)
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
-- TOC entry 5580 (class 0 OID 0)
-- Dependencies: 249
-- Name: user_account_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_account_user_id_seq OWNED BY public.user_account.user_id;


--
-- TOC entry 250 (class 1259 OID 17338)
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
-- TOC entry 251 (class 1259 OID 17343)
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
-- TOC entry 252 (class 1259 OID 17348)
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
-- TOC entry 253 (class 1259 OID 17353)
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
-- TOC entry 254 (class 1259 OID 17358)
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
-- TOC entry 5265 (class 2604 OID 17362)
-- Name: audit_log audit_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_log ALTER COLUMN audit_id SET DEFAULT nextval('public.audit_log_audit_id_seq'::regclass);


--
-- TOC entry 5267 (class 2604 OID 17363)
-- Name: booking booking_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.booking ALTER COLUMN booking_id SET DEFAULT nextval('public.booking_booking_id_seq'::regclass);


--
-- TOC entry 5275 (class 2604 OID 17364)
-- Name: branch branch_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.branch ALTER COLUMN branch_id SET DEFAULT nextval('public.branch_branch_id_seq'::regclass);


--
-- TOC entry 5276 (class 2604 OID 17365)
-- Name: customer customer_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer ALTER COLUMN customer_id SET DEFAULT nextval('public.customer_customer_id_seq'::regclass);


--
-- TOC entry 5278 (class 2604 OID 17366)
-- Name: employee employee_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee ALTER COLUMN employee_id SET DEFAULT nextval('public.employee_employee_id_seq'::regclass);


--
-- TOC entry 5279 (class 2604 OID 17367)
-- Name: guest guest_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.guest ALTER COLUMN guest_id SET DEFAULT nextval('public.guest_guest_id_seq'::regclass);


--
-- TOC entry 5280 (class 2604 OID 17368)
-- Name: invoice invoice_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoice ALTER COLUMN invoice_id SET DEFAULT nextval('public.invoice_invoice_id_seq'::regclass);


--
-- TOC entry 5282 (class 2604 OID 17369)
-- Name: payment payment_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment ALTER COLUMN payment_id SET DEFAULT nextval('public.payment_payment_id_seq'::regclass);


--
-- TOC entry 5284 (class 2604 OID 17370)
-- Name: payment_adjustment adjustment_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment_adjustment ALTER COLUMN adjustment_id SET DEFAULT nextval('public.payment_adjustment_adjustment_id_seq'::regclass);


--
-- TOC entry 5286 (class 2604 OID 17371)
-- Name: pre_booking pre_booking_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pre_booking ALTER COLUMN pre_booking_id SET DEFAULT nextval('public.pre_booking_pre_booking_id_seq'::regclass);


--
-- TOC entry 5288 (class 2604 OID 17372)
-- Name: room room_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.room ALTER COLUMN room_id SET DEFAULT nextval('public.room_room_id_seq'::regclass);


--
-- TOC entry 5290 (class 2604 OID 17373)
-- Name: room_type room_type_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.room_type ALTER COLUMN room_type_id SET DEFAULT nextval('public.room_type_room_type_id_seq'::regclass);


--
-- TOC entry 5291 (class 2604 OID 17374)
-- Name: service_catalog service_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_catalog ALTER COLUMN service_id SET DEFAULT nextval('public.service_catalog_service_id_seq'::regclass);


--
-- TOC entry 5294 (class 2604 OID 17375)
-- Name: service_usage service_usage_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_usage ALTER COLUMN service_usage_id SET DEFAULT nextval('public.service_usage_service_usage_id_seq'::regclass);


--
-- TOC entry 5296 (class 2604 OID 17376)
-- Name: user_account user_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_account ALTER COLUMN user_id SET DEFAULT nextval('public.user_account_user_id_seq'::regclass);


--
-- TOC entry 5530 (class 0 OID 17183)
-- Dependencies: 220
-- Data for Name: audit_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.audit_log (audit_id, actor, action, entity, entity_id, details, created_at) FROM stdin;
1	admin	UPDATE	payment	728	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
2	recept_kandy	UPDATE	service_usage	813	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
3	manager_col	INSERT	service_usage	278	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
4	recept_kandy	UPDATE	payment	467	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
5	manager_col	INSERT	booking	892	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
6	acc_galle	DELETE	payment	584	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
7	recept_kandy	UPDATE	payment	357	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
8	acc_galle	UPDATE	payment	392	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
9	recept_kandy	UPDATE	payment	80	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
10	acc_galle	INSERT	service_usage	485	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
11	manager_col	DELETE	service_usage	33	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
12	acc_galle	INSERT	booking	934	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
13	manager_col	INSERT	payment	989	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
14	recept_kandy	INSERT	booking	709	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
15	admin	UPDATE	service_usage	932	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
16	recept_kandy	DELETE	payment	227	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
17	acc_galle	UPDATE	payment	581	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
18	manager_col	UPDATE	payment	476	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
19	manager_col	UPDATE	booking	825	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
20	recept_kandy	INSERT	payment	483	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
21	recept_kandy	UPDATE	payment	690	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
22	recept_kandy	INSERT	payment	111	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
23	manager_col	INSERT	payment	389	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
24	admin	INSERT	payment	920	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
25	manager_col	UPDATE	booking	286	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
26	recept_kandy	INSERT	booking	561	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
27	manager_col	DELETE	booking	351	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
28	manager_col	DELETE	booking	73	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
29	recept_kandy	DELETE	payment	26	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
30	manager_col	DELETE	payment	124	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
31	manager_col	UPDATE	booking	982	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
32	acc_galle	INSERT	service_usage	36	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
33	recept_kandy	UPDATE	booking	647	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
34	acc_galle	UPDATE	payment	849	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
35	manager_col	INSERT	payment	827	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
36	recept_kandy	UPDATE	service_usage	163	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
37	admin	INSERT	payment	327	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
38	recept_kandy	INSERT	payment	350	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
39	manager_col	DELETE	payment	836	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
40	manager_col	UPDATE	booking	536	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
41	manager_col	DELETE	booking	798	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
42	manager_col	UPDATE	service_usage	385	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
43	manager_col	INSERT	payment	861	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
44	acc_galle	INSERT	booking	771	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
45	recept_kandy	UPDATE	booking	623	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
46	recept_kandy	UPDATE	payment	644	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
47	manager_col	UPDATE	payment	582	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
48	acc_galle	INSERT	payment	32	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
49	recept_kandy	DELETE	booking	361	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
50	recept_kandy	UPDATE	booking	278	{"info": "simulated audit entry", "timestamp": "2025-10-05T15:04:10.097053+05:30"}	2025-10-05 15:04:10.097053
52	recept_kandy	DELETE	service_usage	878	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
53	recept_kandy	DELETE	service_usage	375	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
54	recept_kandy	DELETE	service_usage	596	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
55	recept_kandy	DELETE	service_usage	513	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
56	recept_kandy	DELETE	service_usage	996	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
57	recept_kandy	DELETE	service_usage	820	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
58	recept_kandy	DELETE	service_usage	80	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
59	recept_kandy	DELETE	service_usage	717	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
60	recept_kandy	DELETE	service_usage	650	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
61	recept_kandy	DELETE	service_usage	720	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
62	recept_kandy	DELETE	service_usage	414	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
63	recept_kandy	DELETE	service_usage	825	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
64	recept_kandy	DELETE	service_usage	782	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
65	recept_kandy	DELETE	service_usage	696	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
66	recept_kandy	DELETE	service_usage	988	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
67	recept_kandy	DELETE	service_usage	334	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
68	recept_kandy	DELETE	service_usage	134	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
69	recept_kandy	DELETE	service_usage	165	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
70	recept_kandy	DELETE	service_usage	570	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
71	recept_kandy	DELETE	service_usage	301	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
72	recept_kandy	DELETE	service_usage	807	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
73	recept_kandy	DELETE	service_usage	129	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
74	recept_kandy	DELETE	service_usage	367	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
75	recept_kandy	DELETE	service_usage	591	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
76	recept_kandy	DELETE	service_usage	629	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
77	recept_kandy	DELETE	service_usage	847	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
78	recept_kandy	DELETE	service_usage	983	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
79	recept_kandy	DELETE	service_usage	54	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
80	recept_kandy	DELETE	service_usage	166	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
81	recept_kandy	DELETE	service_usage	238	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
82	recept_kandy	DELETE	service_usage	27	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
83	recept_kandy	DELETE	service_usage	326	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
84	recept_kandy	DELETE	service_usage	424	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
85	recept_kandy	DELETE	service_usage	159	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
86	recept_kandy	DELETE	service_usage	180	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
87	recept_kandy	DELETE	service_usage	508	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
88	recept_kandy	DELETE	service_usage	887	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
89	recept_kandy	DELETE	service_usage	246	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
90	recept_kandy	DELETE	service_usage	312	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
91	recept_kandy	DELETE	service_usage	477	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
92	recept_kandy	DELETE	service_usage	429	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
93	recept_kandy	DELETE	service_usage	194	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
94	recept_kandy	DELETE	service_usage	493	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
95	recept_kandy	DELETE	service_usage	950	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
96	recept_kandy	DELETE	service_usage	614	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
97	recept_kandy	DELETE	service_usage	924	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
98	recept_kandy	DELETE	service_usage	921	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
99	recept_kandy	DELETE	service_usage	541	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
100	recept_kandy	DELETE	service_usage	774	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
101	recept_kandy	DELETE	service_usage	243	{"info": "simulated audit entry", "timestamp": "2025-10-05T16:00:25.101475+05:30"}	2025-10-05 16:00:25.101475
\.


--
-- TOC entry 5532 (class 0 OID 17194)
-- Dependencies: 222
-- Data for Name: booking; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.booking (booking_id, pre_booking_id, guest_id, room_id, check_in_date, check_out_date, status, booked_rate, tax_rate_percent, discount_amount, late_fee_amount, preferred_payment_method, advance_payment, created_at) FROM stdin;
1426	\N	151	11	2025-10-10	2025-10-14	Booked	0.00	0.00	0.00	0.00	\N	0.00	2025-10-06 23:33:18.829019+05:30
1427	\N	151	31	2025-10-10	2025-10-14	Booked	0.00	0.00	0.00	0.00	\N	0.00	2025-10-06 23:33:18.829019+05:30
1428	\N	151	51	2025-10-10	2025-10-14	Booked	0.00	0.00	0.00	0.00	\N	0.00	2025-10-06 23:33:18.829019+05:30
2	\N	66	1	2025-07-05	2025-07-08	Checked-Out	43200.00	10.00	0.00	0.00	Card	12960.00	2025-10-06 23:33:18.829019+05:30
3	\N	89	1	2025-07-08	2025-07-13	Checked-In	40000.00	10.00	0.00	0.00	Cash	20000.00	2025-10-06 23:33:18.829019+05:30
868	\N	58	37	2025-09-05	2025-09-06	Checked-Out	14256.00	10.00	0.00	2956.45	Online	1425.60	2025-10-06 23:33:18.829019+05:30
887	\N	143	38	2025-08-08	2025-08-12	Checked-Out	14256.00	10.00	0.00	2478.36	Card	5702.40	2025-10-06 23:33:18.829019+05:30
889	\N	86	38	2025-08-16	2025-08-17	Checked-In	14256.00	10.00	0.00	2484.40	Online	1425.60	2025-10-06 23:33:18.829019+05:30
1145	\N	16	49	2025-08-10	2025-08-13	Checked-Out	19800.00	10.00	2432.15	2042.81	Cash	5940.00	2025-10-06 23:33:18.829019+05:30
5	\N	114	1	2025-07-22	2025-07-26	Booked	40000.00	10.00	0.00	0.00	Card	16000.00	2025-10-06 23:33:18.829019+05:30
14	\N	28	1	2025-08-30	2025-08-31	Booked	47520.00	10.00	0.00	0.00	Cash	4752.00	2025-10-06 23:33:18.829019+05:30
48	\N	122	3	2025-07-06	2025-07-09	Booked	40000.00	10.00	0.00	0.00	Cash	12000.00	2025-10-06 23:33:18.829019+05:30
175	\N	93	8	2025-07-30	2025-08-03	Booked	24000.00	10.00	0.00	0.00	Online	9600.00	2025-10-06 23:33:18.829019+05:30
293	\N	51	13	2025-08-01	2025-08-04	Booked	21384.00	10.00	0.00	0.00	Online	6415.20	2025-10-06 23:33:18.829019+05:30
298	\N	118	13	2025-08-23	2025-08-26	Booked	21384.00	10.00	0.00	0.00	Card	6415.20	2025-10-06 23:33:18.829019+05:30
316	\N	93	14	2025-08-11	2025-08-13	Booked	19800.00	10.00	2432.15	0.00	Online	3960.00	2025-10-06 23:33:18.829019+05:30
348	\N	138	15	2025-09-16	2025-09-18	Booked	19800.00	10.00	2666.03	0.00	Online	3960.00	2025-10-06 23:33:18.829019+05:30
366	\N	102	16	2025-08-14	2025-08-17	Booked	13200.00	10.00	0.00	0.00	BankTransfer	3960.00	2025-10-06 23:33:18.829019+05:30
377	\N	58	16	2025-09-25	2025-09-28	Booked	13200.00	10.00	0.00	0.00	Cash	3960.00	2025-10-06 23:33:18.829019+05:30
547	\N	8	24	2025-07-13	2025-07-15	Booked	24000.00	10.00	0.00	4381.44	Card	4800.00	2025-10-06 23:33:18.829019+05:30
551	\N	147	24	2025-07-24	2025-07-26	Booked	24000.00	10.00	2948.06	0.00	Online	4800.00	2025-10-06 23:33:18.829019+05:30
561	\N	34	24	2025-09-01	2025-09-04	Booked	26400.00	10.00	0.00	0.00	BankTransfer	7920.00	2025-10-06 23:33:18.829019+05:30
564	\N	97	24	2025-09-15	2025-09-18	Booked	26400.00	10.00	0.00	0.00	Online	7920.00	2025-10-06 23:33:18.829019+05:30
679	\N	43	29	2025-09-04	2025-09-05	Booked	19800.00	10.00	1388.24	0.00	Card	1980.00	2025-10-06 23:33:18.829019+05:30
687	\N	126	30	2025-07-03	2025-07-04	Booked	18000.00	10.00	956.92	0.00	Card	1800.00	2025-10-06 23:33:18.829019+05:30
764	\N	54	33	2025-09-01	2025-09-04	Booked	19800.00	10.00	0.00	4646.87	BankTransfer	5940.00	2025-10-06 23:33:18.829019+05:30
843	\N	58	36	2025-08-28	2025-09-02	Booked	13200.00	10.00	0.00	0.00	Online	6600.00	2025-10-06 23:33:18.829019+05:30
990	\N	39	43	2025-07-06	2025-07-08	Booked	40000.00	10.00	0.00	0.00	BankTransfer	8000.00	2025-10-06 23:33:18.829019+05:30
1003	\N	32	43	2025-08-29	2025-09-01	Booked	47520.00	10.00	0.00	0.00	Card	14256.00	2025-10-06 23:33:18.829019+05:30
1009	\N	16	43	2025-09-20	2025-09-23	Booked	47520.00	10.00	5540.43	0.00	Cash	14256.00	2025-10-06 23:33:18.829019+05:30
1018	\N	50	44	2025-07-29	2025-08-02	Booked	24000.00	10.00	0.00	0.00	Cash	9600.00	2025-10-06 23:33:18.829019+05:30
1030	\N	111	44	2025-09-16	2025-09-18	Booked	26400.00	10.00	3242.87	0.00	BankTransfer	5280.00	2025-10-06 23:33:18.829019+05:30
1070	\N	117	46	2025-08-04	2025-08-08	Booked	26400.00	10.00	0.00	0.00	Cash	10560.00	2025-10-06 23:33:18.829019+05:30
1073	\N	118	46	2025-08-12	2025-08-16	Booked	26400.00	10.00	0.00	0.00	Online	10560.00	2025-10-06 23:33:18.829019+05:30
1088	\N	24	47	2025-07-17	2025-07-20	Booked	24000.00	10.00	0.00	0.00	Online	7200.00	2025-10-06 23:33:18.829019+05:30
1213	\N	108	52	2025-08-01	2025-08-06	Booked	21384.00	10.00	1331.86	0.00	BankTransfer	10692.00	2025-10-06 23:33:18.829019+05:30
1221	\N	108	52	2025-08-27	2025-08-30	Booked	19800.00	10.00	3349.15	0.00	Online	5940.00	2025-10-06 23:33:18.829019+05:30
1306	\N	45	56	2025-07-28	2025-07-30	Booked	12000.00	10.00	0.00	0.00	Online	2400.00	2025-10-06 23:33:18.829019+05:30
1385	\N	130	59	2025-09-26	2025-09-29	Booked	14256.00	10.00	0.00	0.00	Card	4276.80	2025-10-06 23:33:18.829019+05:30
1390	\N	130	60	2025-07-14	2025-07-17	Booked	12000.00	10.00	0.00	0.00	Cash	3600.00	2025-10-06 23:33:18.829019+05:30
1398	\N	109	60	2025-08-15	2025-08-18	Booked	14256.00	10.00	0.00	1905.08	Cash	4276.80	2025-10-06 23:33:18.829019+05:30
1411	\N	71	32	2025-10-22	2025-10-24	Booked	18000.00	10.00	0.00	0.00	Online	3600.00	2025-10-06 23:33:18.829019+05:30
1414	\N	108	56	2025-10-11	2025-10-13	Booked	12000.00	10.00	0.00	0.00	Card	2400.00	2025-10-06 23:33:18.829019+05:30
1417	\N	107	14	2025-10-16	2025-10-17	Booked	18000.00	10.00	0.00	0.00	BankTransfer	1800.00	2025-10-06 23:33:18.829019+05:30
1419	\N	116	41	2025-10-16	2025-10-19	Booked	40000.00	10.00	0.00	0.00	Card	12000.00	2025-10-06 23:33:18.829019+05:30
1420	\N	81	56	2025-10-06	2025-10-08	Booked	12000.00	10.00	0.00	0.00	Card	2400.00	2025-10-06 23:33:18.829019+05:30
1421	\N	115	35	2025-10-22	2025-10-25	Booked	18000.00	10.00	0.00	0.00	Online	5400.00	2025-10-06 23:33:18.829019+05:30
1424	\N	72	51	2025-10-18	2025-10-23	Booked	18000.00	10.00	0.00	0.00	Online	9000.00	2025-10-06 23:33:18.829019+05:30
1412	\N	6	54	2025-10-19	2025-10-22	Booked	18000.00	10.00	3242.48	0.00	Cash	5400.00	2025-10-06 23:33:18.829019+05:30
1416	\N	92	3	2025-10-19	2025-10-21	Booked	40000.00	10.00	4828.13	0.00	Cash	8000.00	2025-10-06 23:33:18.829019+05:30
1418	\N	134	16	2025-10-10	2025-10-13	Booked	12000.00	10.00	925.30	0.00	Cash	3600.00	2025-10-06 23:33:18.829019+05:30
1413	\N	103	44	2025-10-11	2025-10-15	Booked	24000.00	10.00	2948.06	0.00	Cash	9600.00	2025-10-06 23:33:18.829019+05:30
1423	\N	34	43	2025-10-19	2025-10-21	Booked	40000.00	10.00	3689.43	10867.70	Cash	8000.00	2025-10-06 23:33:18.829019+05:30
1415	\N	22	56	2025-10-18	2025-10-23	Booked	12000.00	10.00	1474.03	2882.54	Cash	6000.00	2025-10-06 23:33:18.829019+05:30
619	\N	36	27	2025-07-24	2025-07-26	Booked	24000.00	10.00	2743.83	0.00	Online	4800.00	2025-10-06 23:33:18.829019+05:30
620	\N	120	27	2025-07-27	2025-07-30	Booked	24000.00	10.00	2378.90	0.00	BankTransfer	7200.00	2025-10-06 23:33:18.829019+05:30
922	\N	31	40	2025-07-01	2025-07-03	Booked	12000.00	10.00	2190.04	0.00	Online	2400.00	2025-10-06 23:33:18.829019+05:30
1236	\N	16	53	2025-07-28	2025-08-01	Booked	18000.00	10.00	3141.09	0.00	Card	7200.00	2025-10-06 23:33:18.829019+05:30
1320	\N	108	56	2025-09-30	2025-10-04	Booked	13200.00	10.00	1147.84	1338.08	BankTransfer	5280.00	2025-10-06 23:33:18.829019+05:30
77	\N	119	4	2025-07-20	2025-07-23	Booked	24000.00	10.00	3054.97	0.00	Cash	7200.00	2025-10-06 23:33:18.829019+05:30
1422	\N	53	17	2025-10-08	2025-10-11	Booked	12000.00	10.00	927.23	0.00	Online	3600.00	2025-10-06 23:33:18.829019+05:30
452	\N	119	20	2025-07-07	2025-07-11	Booked	12000.00	10.00	2173.13	0.00	Online	4800.00	2025-10-06 23:33:18.829019+05:30
1431	\N	1	1	2025-11-10	2025-11-12	Booked	20000.00	10.00	0.00	0.00	\N	4000.00	2025-10-06 23:33:18.829019+05:30
1429	\N	1	1	2025-10-10	2025-10-12	Booked	15000.00	10.00	0.00	0.00	\N	20000.00	2025-10-06 23:33:18.829019+05:30
1430	\N	2	2	2025-10-06	2025-10-08	Booked	15000.00	10.00	0.00	0.00	\N	20000.00	2025-10-06 23:33:18.829019+05:30
91	\N	135	4	2025-09-19	2025-09-20	Checked-In	28512.00	10.00	0.00	0.00	Online	2851.20	2025-10-06 23:33:18.829019+05:30
4	\N	83	1	2025-07-15	2025-07-20	Checked-In	40000.00	10.00	0.00	0.00	Card	20000.00	2025-10-06 23:33:18.829019+05:30
6	\N	136	1	2025-07-26	2025-07-31	Checked-In	43200.00	10.00	0.00	0.00	Card	21600.00	2025-10-06 23:33:18.829019+05:30
9	\N	65	1	2025-08-08	2025-08-12	Checked-Out	47520.00	10.00	0.00	0.00	Card	19008.00	2025-10-06 23:33:18.829019+05:30
10	\N	74	1	2025-08-13	2025-08-16	Checked-Out	44000.00	10.00	0.00	0.00	Card	13200.00	2025-10-06 23:33:18.829019+05:30
11	\N	7	1	2025-08-17	2025-08-21	Checked-In	44000.00	10.00	0.00	0.00	Online	17600.00	2025-10-06 23:33:18.829019+05:30
12	\N	132	1	2025-08-23	2025-08-27	Checked-Out	47520.00	10.00	0.00	0.00	Cash	19008.00	2025-10-06 23:33:18.829019+05:30
13	\N	74	1	2025-08-29	2025-08-30	Checked-In	47520.00	10.00	0.00	0.00	Online	4752.00	2025-10-06 23:33:18.829019+05:30
18	\N	125	1	2025-09-16	2025-09-20	Checked-Out	44000.00	10.00	0.00	0.00	Card	17600.00	2025-10-06 23:33:18.829019+05:30
19	\N	133	1	2025-09-20	2025-09-21	Checked-Out	47520.00	10.00	0.00	0.00	BankTransfer	4752.00	2025-10-06 23:33:18.829019+05:30
22	\N	1	2	2025-07-01	2025-07-04	Checked-Out	40000.00	10.00	0.00	0.00	BankTransfer	12000.00	2025-10-06 23:33:18.829019+05:30
23	\N	132	2	2025-07-04	2025-07-08	Checked-Out	43200.00	10.00	0.00	0.00	BankTransfer	17280.00	2025-10-06 23:33:18.829019+05:30
26	\N	150	2	2025-07-16	2025-07-18	Checked-Out	40000.00	10.00	0.00	0.00	Cash	8000.00	2025-10-06 23:33:18.829019+05:30
27	\N	139	2	2025-07-20	2025-07-24	Checked-Out	40000.00	10.00	0.00	0.00	Card	16000.00	2025-10-06 23:33:18.829019+05:30
29	\N	109	2	2025-07-28	2025-07-30	Checked-Out	40000.00	10.00	0.00	0.00	Cash	8000.00	2025-10-06 23:33:18.829019+05:30
30	\N	67	2	2025-08-01	2025-08-02	Checked-Out	47520.00	10.00	0.00	0.00	Cash	4752.00	2025-10-06 23:33:18.829019+05:30
31	\N	97	2	2025-08-02	2025-08-05	Checked-Out	47520.00	10.00	0.00	0.00	Online	14256.00	2025-10-06 23:33:18.829019+05:30
32	\N	70	2	2025-08-06	2025-08-10	Checked-Out	44000.00	10.00	0.00	0.00	Online	17600.00	2025-10-06 23:33:18.829019+05:30
36	\N	41	2	2025-08-22	2025-08-26	Checked-Out	47520.00	10.00	0.00	0.00	Card	19008.00	2025-10-06 23:33:18.829019+05:30
37	\N	119	2	2025-08-26	2025-08-29	Checked-In	44000.00	10.00	0.00	0.00	Card	13200.00	2025-10-06 23:33:18.829019+05:30
38	\N	116	2	2025-08-31	2025-09-02	Checked-Out	44000.00	10.00	0.00	0.00	Card	8800.00	2025-10-06 23:33:18.829019+05:30
39	\N	32	2	2025-09-04	2025-09-06	Checked-Out	44000.00	10.00	0.00	0.00	Online	8800.00	2025-10-06 23:33:18.829019+05:30
40	\N	14	2	2025-09-07	2025-09-10	Checked-Out	44000.00	10.00	0.00	0.00	Cash	13200.00	2025-10-06 23:33:18.829019+05:30
41	\N	33	2	2025-09-12	2025-09-16	Checked-Out	47520.00	10.00	0.00	0.00	Online	19008.00	2025-10-06 23:33:18.829019+05:30
42	\N	30	2	2025-09-16	2025-09-19	Checked-Out	44000.00	10.00	0.00	0.00	BankTransfer	13200.00	2025-10-06 23:33:18.829019+05:30
43	\N	85	2	2025-09-19	2025-09-22	Checked-Out	47520.00	10.00	0.00	0.00	Card	14256.00	2025-10-06 23:33:18.829019+05:30
44	\N	84	2	2025-09-22	2025-09-25	Checked-Out	44000.00	10.00	0.00	0.00	BankTransfer	13200.00	2025-10-06 23:33:18.829019+05:30
45	\N	37	2	2025-09-26	2025-09-29	Checked-Out	47520.00	10.00	0.00	0.00	Online	14256.00	2025-10-06 23:33:18.829019+05:30
46	\N	14	2	2025-09-30	2025-10-04	Checked-In	44000.00	10.00	0.00	0.00	Cash	17600.00	2025-10-06 23:33:18.829019+05:30
49	\N	92	3	2025-07-10	2025-07-11	Checked-In	40000.00	10.00	0.00	0.00	Cash	4000.00	2025-10-06 23:33:18.829019+05:30
53	\N	62	3	2025-07-23	2025-07-26	Checked-Out	40000.00	10.00	0.00	0.00	Online	12000.00	2025-10-06 23:33:18.829019+05:30
54	\N	88	3	2025-07-27	2025-07-30	Checked-Out	40000.00	10.00	0.00	0.00	Card	12000.00	2025-10-06 23:33:18.829019+05:30
55	\N	18	3	2025-07-31	2025-08-05	Checked-Out	40000.00	10.00	0.00	0.00	Online	20000.00	2025-10-06 23:33:18.829019+05:30
56	\N	76	3	2025-08-05	2025-08-07	Checked-Out	44000.00	10.00	0.00	0.00	BankTransfer	8800.00	2025-10-06 23:33:18.829019+05:30
58	\N	13	3	2025-08-13	2025-08-15	Checked-Out	44000.00	10.00	0.00	0.00	Card	8800.00	2025-10-06 23:33:18.829019+05:30
59	\N	102	3	2025-08-17	2025-08-20	Checked-Out	44000.00	10.00	0.00	0.00	Online	13200.00	2025-10-06 23:33:18.829019+05:30
62	\N	7	3	2025-08-28	2025-09-01	Checked-Out	44000.00	10.00	0.00	0.00	BankTransfer	17600.00	2025-10-06 23:33:18.829019+05:30
68	\N	46	3	2025-09-26	2025-09-27	Checked-Out	47520.00	10.00	0.00	0.00	Online	4752.00	2025-10-06 23:33:18.829019+05:30
69	\N	58	3	2025-09-28	2025-10-01	Checked-Out	44000.00	10.00	0.00	0.00	BankTransfer	13200.00	2025-10-06 23:33:18.829019+05:30
70	\N	90	4	2025-07-01	2025-07-04	Checked-Out	24000.00	10.00	0.00	0.00	Online	7200.00	2025-10-06 23:33:18.829019+05:30
71	\N	102	4	2025-07-05	2025-07-09	Checked-Out	25920.00	10.00	0.00	0.00	Cash	10368.00	2025-10-06 23:33:18.829019+05:30
75	\N	96	4	2025-07-16	2025-07-18	Checked-Out	24000.00	10.00	0.00	0.00	Online	4800.00	2025-10-06 23:33:18.829019+05:30
80	\N	57	4	2025-08-04	2025-08-06	Checked-Out	26400.00	10.00	0.00	0.00	Online	5280.00	2025-10-06 23:33:18.829019+05:30
81	\N	146	4	2025-08-08	2025-08-11	Checked-Out	28512.00	10.00	0.00	0.00	BankTransfer	8553.60	2025-10-06 23:33:18.829019+05:30
73	\N	60	4	2025-07-12	2025-07-14	Checked-Out	25920.00	10.00	3183.90	0.00	Cash	5184.00	2025-10-06 23:33:18.829019+05:30
16	\N	19	1	2025-09-06	2025-09-11	Checked-Out	47520.00	10.00	7197.75	0.00	Online	23760.00	2025-10-06 23:33:18.829019+05:30
24	\N	118	2	2025-07-09	2025-07-12	Checked-Out	40000.00	10.00	3239.52	0.00	Online	12000.00	2025-10-06 23:33:18.829019+05:30
28	\N	94	2	2025-07-24	2025-07-27	Checked-Out	40000.00	10.00	6744.25	0.00	Card	12000.00	2025-10-06 23:33:18.829019+05:30
17	\N	80	1	2025-09-11	2025-09-15	Cancelled	44000.00	10.00	0.00	0.00	Cash	17600.00	2025-10-06 23:33:18.829019+05:30
35	\N	112	2	2025-08-18	2025-08-21	Checked-Out	44000.00	10.00	4928.22	0.00	Cash	13200.00	2025-10-06 23:33:18.829019+05:30
67	\N	127	3	2025-09-21	2025-09-26	Checked-In	44000.00	10.00	0.00	12554.14	Online	22000.00	2025-10-06 23:33:18.829019+05:30
51	\N	53	3	2025-07-15	2025-07-19	Checked-In	40000.00	10.00	7358.12	0.00	Cash	16000.00	2025-10-06 23:33:18.829019+05:30
60	\N	67	3	2025-08-21	2025-08-24	Checked-In	44000.00	10.00	5637.98	0.00	Cash	13200.00	2025-10-06 23:33:18.829019+05:30
57	\N	67	3	2025-08-08	2025-08-11	Checked-Out	47520.00	10.00	4810.47	0.00	Cash	14256.00	2025-10-06 23:33:18.829019+05:30
61	\N	40	3	2025-08-24	2025-08-27	Checked-Out	44000.00	10.00	8119.97	0.00	BankTransfer	13200.00	2025-10-06 23:33:18.829019+05:30
65	\N	29	3	2025-09-10	2025-09-14	Checked-Out	44000.00	10.00	8528.53	0.00	Online	17600.00	2025-10-06 23:33:18.829019+05:30
8	\N	50	1	2025-08-03	2025-08-08	Checked-Out	44000.00	10.00	7091.78	0.00	Card	22000.00	2025-10-06 23:33:18.829019+05:30
33	\N	137	2	2025-08-11	2025-08-13	Checked-In	44000.00	10.00	3703.85	0.00	Online	8800.00	2025-10-06 23:33:18.829019+05:30
21	\N	75	1	2025-09-26	2025-10-01	Cancelled	47520.00	10.00	0.00	0.00	Online	23760.00	2025-10-06 23:33:18.829019+05:30
74	\N	110	4	2025-07-14	2025-07-15	Cancelled	24000.00	10.00	0.00	0.00	BankTransfer	2400.00	2025-10-06 23:33:18.829019+05:30
79	\N	93	4	2025-07-30	2025-08-02	Cancelled	24000.00	10.00	0.00	0.00	Cash	7200.00	2025-10-06 23:33:18.829019+05:30
47	\N	33	3	2025-07-01	2025-07-04	Cancelled	40000.00	10.00	4198.19	0.00	Cash	12000.00	2025-10-06 23:33:18.829019+05:30
72	\N	145	4	2025-07-10	2025-07-12	Checked-Out	24000.00	10.00	0.00	3329.90	Cash	4800.00	2025-10-06 23:33:18.829019+05:30
183	\N	140	8	2025-09-02	2025-09-05	Checked-Out	26400.00	10.00	0.00	0.00	Cash	7920.00	2025-10-06 23:33:18.829019+05:30
184	\N	20	8	2025-09-06	2025-09-07	Checked-Out	28512.00	10.00	0.00	0.00	Cash	2851.20	2025-10-06 23:33:18.829019+05:30
82	\N	8	4	2025-08-12	2025-08-15	Checked-Out	26400.00	10.00	0.00	5553.42	BankTransfer	7920.00	2025-10-06 23:33:18.829019+05:30
7	\N	35	1	2025-07-31	2025-08-03	Checked-Out	40000.00	10.00	5312.72	8562.21	Online	12000.00	2025-10-06 23:33:18.829019+05:30
84	\N	109	4	2025-08-20	2025-08-23	Checked-Out	26400.00	10.00	0.00	0.00	Online	7920.00	2025-10-06 23:33:18.829019+05:30
87	\N	77	4	2025-08-31	2025-09-02	Checked-Out	26400.00	10.00	0.00	0.00	Cash	5280.00	2025-10-06 23:33:18.829019+05:30
88	\N	17	4	2025-09-04	2025-09-08	Checked-In	26400.00	10.00	0.00	0.00	Card	10560.00	2025-10-06 23:33:18.829019+05:30
90	\N	102	4	2025-09-14	2025-09-19	Checked-Out	26400.00	10.00	0.00	0.00	Online	13200.00	2025-10-06 23:33:18.829019+05:30
92	\N	97	4	2025-09-22	2025-09-27	Checked-Out	26400.00	10.00	0.00	0.00	Cash	13200.00	2025-10-06 23:33:18.829019+05:30
93	\N	83	4	2025-09-28	2025-09-29	Checked-Out	26400.00	10.00	0.00	0.00	Card	2640.00	2025-10-06 23:33:18.829019+05:30
94	\N	145	5	2025-07-01	2025-07-03	Checked-Out	24000.00	10.00	0.00	0.00	Online	4800.00	2025-10-06 23:33:18.829019+05:30
96	\N	117	5	2025-07-09	2025-07-11	Checked-Out	24000.00	10.00	0.00	0.00	Online	4800.00	2025-10-06 23:33:18.829019+05:30
97	\N	70	5	2025-07-13	2025-07-18	Checked-In	24000.00	10.00	0.00	0.00	Cash	12000.00	2025-10-06 23:33:18.829019+05:30
101	\N	129	5	2025-07-25	2025-07-29	Checked-Out	25920.00	10.00	0.00	0.00	Cash	10368.00	2025-10-06 23:33:18.829019+05:30
102	\N	21	5	2025-07-30	2025-08-03	Checked-Out	24000.00	10.00	0.00	0.00	Cash	9600.00	2025-10-06 23:33:18.829019+05:30
106	\N	38	5	2025-08-18	2025-08-21	Checked-In	26400.00	10.00	0.00	0.00	Cash	7920.00	2025-10-06 23:33:18.829019+05:30
107	\N	76	5	2025-08-21	2025-08-24	Checked-In	26400.00	10.00	0.00	0.00	BankTransfer	7920.00	2025-10-06 23:33:18.829019+05:30
108	\N	119	5	2025-08-26	2025-08-31	Checked-Out	26400.00	10.00	0.00	0.00	Cash	13200.00	2025-10-06 23:33:18.829019+05:30
110	\N	21	5	2025-09-03	2025-09-05	Checked-Out	26400.00	10.00	0.00	0.00	Online	5280.00	2025-10-06 23:33:18.829019+05:30
111	\N	73	5	2025-09-06	2025-09-11	Checked-Out	28512.00	10.00	0.00	0.00	Online	14256.00	2025-10-06 23:33:18.829019+05:30
112	\N	99	5	2025-09-11	2025-09-12	Checked-Out	26400.00	10.00	0.00	0.00	Card	2640.00	2025-10-06 23:33:18.829019+05:30
114	\N	145	5	2025-09-18	2025-09-23	Checked-Out	26400.00	10.00	0.00	0.00	Online	13200.00	2025-10-06 23:33:18.829019+05:30
116	\N	75	5	2025-09-27	2025-10-01	Checked-Out	28512.00	10.00	0.00	0.00	BankTransfer	11404.80	2025-10-06 23:33:18.829019+05:30
118	\N	108	6	2025-07-05	2025-07-06	Checked-Out	25920.00	10.00	0.00	0.00	BankTransfer	2592.00	2025-10-06 23:33:18.829019+05:30
119	\N	59	6	2025-07-07	2025-07-10	Checked-Out	24000.00	10.00	0.00	0.00	Cash	7200.00	2025-10-06 23:33:18.829019+05:30
120	\N	4	6	2025-07-10	2025-07-13	Checked-Out	24000.00	10.00	0.00	0.00	BankTransfer	7200.00	2025-10-06 23:33:18.829019+05:30
123	\N	37	6	2025-07-25	2025-07-29	Checked-In	25920.00	10.00	0.00	0.00	Online	10368.00	2025-10-06 23:33:18.829019+05:30
125	\N	133	6	2025-07-31	2025-08-01	Checked-Out	24000.00	10.00	0.00	0.00	Online	2400.00	2025-10-06 23:33:18.829019+05:30
131	\N	93	6	2025-08-22	2025-08-25	Checked-Out	28512.00	10.00	0.00	0.00	BankTransfer	8553.60	2025-10-06 23:33:18.829019+05:30
132	\N	126	6	2025-08-25	2025-08-28	Checked-Out	26400.00	10.00	0.00	0.00	Cash	7920.00	2025-10-06 23:33:18.829019+05:30
133	\N	44	6	2025-08-29	2025-08-30	Checked-Out	28512.00	10.00	0.00	0.00	Online	2851.20	2025-10-06 23:33:18.829019+05:30
137	\N	97	6	2025-09-10	2025-09-12	Checked-Out	26400.00	10.00	0.00	0.00	Cash	5280.00	2025-10-06 23:33:18.829019+05:30
139	\N	76	6	2025-09-14	2025-09-17	Checked-Out	26400.00	10.00	0.00	0.00	Card	7920.00	2025-10-06 23:33:18.829019+05:30
141	\N	140	6	2025-09-26	2025-09-28	Checked-Out	28512.00	10.00	0.00	0.00	BankTransfer	5702.40	2025-10-06 23:33:18.829019+05:30
143	\N	130	6	2025-09-30	2025-10-04	Checked-Out	26400.00	10.00	0.00	0.00	Online	10560.00	2025-10-06 23:33:18.829019+05:30
144	\N	58	7	2025-07-01	2025-07-04	Checked-Out	24000.00	10.00	0.00	0.00	Card	7200.00	2025-10-06 23:33:18.829019+05:30
145	\N	10	7	2025-07-05	2025-07-08	Checked-Out	25920.00	10.00	0.00	0.00	Online	7776.00	2025-10-06 23:33:18.829019+05:30
146	\N	134	7	2025-07-09	2025-07-13	Checked-Out	24000.00	10.00	0.00	0.00	BankTransfer	9600.00	2025-10-06 23:33:18.829019+05:30
147	\N	89	7	2025-07-14	2025-07-17	Checked-Out	24000.00	10.00	0.00	0.00	Online	7200.00	2025-10-06 23:33:18.829019+05:30
148	\N	62	7	2025-07-18	2025-07-22	Checked-Out	25920.00	10.00	0.00	0.00	Online	10368.00	2025-10-06 23:33:18.829019+05:30
149	\N	108	7	2025-07-23	2025-07-28	Checked-Out	24000.00	10.00	0.00	0.00	BankTransfer	12000.00	2025-10-06 23:33:18.829019+05:30
153	\N	112	7	2025-08-11	2025-08-12	Checked-Out	26400.00	10.00	0.00	0.00	Card	2640.00	2025-10-06 23:33:18.829019+05:30
155	\N	1	7	2025-08-13	2025-08-15	Checked-Out	26400.00	10.00	0.00	0.00	Online	5280.00	2025-10-06 23:33:18.829019+05:30
157	\N	69	7	2025-08-20	2025-08-23	Checked-Out	26400.00	10.00	0.00	0.00	Online	7920.00	2025-10-06 23:33:18.829019+05:30
158	\N	99	7	2025-08-23	2025-08-26	Checked-Out	28512.00	10.00	0.00	0.00	Online	8553.60	2025-10-06 23:33:18.829019+05:30
160	\N	100	7	2025-08-31	2025-09-05	Checked-Out	26400.00	10.00	0.00	0.00	Cash	13200.00	2025-10-06 23:33:18.829019+05:30
161	\N	146	7	2025-09-06	2025-09-10	Checked-Out	28512.00	10.00	0.00	0.00	Cash	11404.80	2025-10-06 23:33:18.829019+05:30
162	\N	52	7	2025-09-11	2025-09-16	Checked-In	26400.00	10.00	0.00	0.00	Online	13200.00	2025-10-06 23:33:18.829019+05:30
151	\N	99	7	2025-08-04	2025-08-05	Cancelled	26400.00	10.00	0.00	0.00	Online	2640.00	2025-10-06 23:33:18.829019+05:30
117	\N	134	6	2025-07-01	2025-07-03	Cancelled	24000.00	10.00	3314.98	0.00	Card	4800.00	2025-10-06 23:33:18.829019+05:30
100	\N	92	5	2025-07-23	2025-07-24	Checked-Out	24000.00	10.00	0.00	2755.56	Card	2400.00	2025-10-06 23:33:18.829019+05:30
134	\N	36	6	2025-08-30	2025-09-02	Checked-Out	28512.00	10.00	4520.06	0.00	Online	8553.60	2025-10-06 23:33:18.829019+05:30
109	\N	73	5	2025-08-31	2025-09-03	Checked-In	26400.00	10.00	0.00	6184.66	Cash	7920.00	2025-10-06 23:33:18.829019+05:30
140	\N	17	6	2025-09-19	2025-09-24	Checked-In	28512.00	10.00	5001.57	0.00	Online	14256.00	2025-10-06 23:33:18.829019+05:30
85	\N	104	4	2025-08-24	2025-08-25	Checked-Out	26400.00	10.00	2617.67	0.00	Card	2640.00	2025-10-06 23:33:18.829019+05:30
89	\N	139	4	2025-09-09	2025-09-13	Checked-Out	26400.00	10.00	3362.60	0.00	Cash	10560.00	2025-10-06 23:33:18.829019+05:30
98	\N	132	5	2025-07-19	2025-07-20	Checked-Out	25920.00	10.00	3343.50	0.00	BankTransfer	2592.00	2025-10-06 23:33:18.829019+05:30
99	\N	142	5	2025-07-21	2025-07-22	Checked-In	24000.00	10.00	4385.09	0.00	Card	2400.00	2025-10-06 23:33:18.829019+05:30
142	\N	19	6	2025-09-29	2025-09-30	Checked-Out	26400.00	10.00	0.00	7177.38	Card	2640.00	2025-10-06 23:33:18.829019+05:30
105	\N	120	5	2025-08-16	2025-08-18	Checked-Out	28512.00	10.00	1902.87	0.00	BankTransfer	5702.40	2025-10-06 23:33:18.829019+05:30
122	\N	63	6	2025-07-18	2025-07-23	Checked-Out	25920.00	10.00	4408.32	0.00	Card	12960.00	2025-10-06 23:33:18.829019+05:30
154	\N	102	7	2025-08-12	2025-08-13	Checked-Out	26400.00	10.00	2517.87	0.00	Online	2640.00	2025-10-06 23:33:18.829019+05:30
86	\N	81	4	2025-08-25	2025-08-30	Checked-In	26400.00	10.00	3242.87	0.00	Card	13200.00	2025-10-06 23:33:18.829019+05:30
103	\N	69	5	2025-08-04	2025-08-09	Checked-Out	26400.00	10.00	3242.87	0.00	Online	13200.00	2025-10-06 23:33:18.829019+05:30
113	\N	83	5	2025-09-13	2025-09-16	Checked-Out	28512.00	10.00	3502.30	0.00	Online	8553.60	2025-10-06 23:33:18.829019+05:30
265	\N	78	12	2025-07-12	2025-07-14	Checked-Out	19440.00	10.00	0.00	0.00	Online	3888.00	2025-10-06 23:33:18.829019+05:30
271	\N	54	12	2025-08-06	2025-08-08	Checked-Out	19800.00	10.00	0.00	0.00	Online	3960.00	2025-10-06 23:33:18.829019+05:30
272	\N	49	12	2025-08-09	2025-08-13	Checked-Out	21384.00	10.00	0.00	0.00	Cash	8553.60	2025-10-06 23:33:18.829019+05:30
130	\N	55	6	2025-08-18	2025-08-22	Checked-In	26400.00	10.00	3242.87	0.00	Online	10560.00	2025-10-06 23:33:18.829019+05:30
159	\N	49	7	2025-08-26	2025-08-30	Checked-Out	26400.00	10.00	3242.87	0.00	Cash	10560.00	2025-10-06 23:33:18.829019+05:30
115	\N	101	5	2025-09-23	2025-09-25	Checked-Out	26400.00	10.00	3242.87	0.00	Online	5280.00	2025-10-06 23:33:18.829019+05:30
135	\N	11	6	2025-09-04	2025-09-06	Checked-Out	26400.00	10.00	1460.74	6410.33	Cash	5280.00	2025-10-06 23:33:18.829019+05:30
95	\N	122	5	2025-07-05	2025-07-08	Checked-Out	25920.00	10.00	3183.90	5243.45	Cash	7776.00	2025-10-06 23:33:18.829019+05:30
150	\N	98	7	2025-07-30	2025-08-02	Checked-Out	24000.00	10.00	2948.06	6310.40	Online	7200.00	2025-10-06 23:33:18.829019+05:30
166	\N	117	7	2025-09-30	2025-10-04	Checked-Out	26400.00	10.00	0.00	0.00	Cash	10560.00	2025-10-06 23:33:18.829019+05:30
169	\N	58	8	2025-07-11	2025-07-12	Checked-Out	25920.00	10.00	0.00	0.00	BankTransfer	2592.00	2025-10-06 23:33:18.829019+05:30
170	\N	79	8	2025-07-14	2025-07-17	Checked-Out	24000.00	10.00	0.00	0.00	Online	7200.00	2025-10-06 23:33:18.829019+05:30
173	\N	30	8	2025-07-26	2025-07-28	Checked-In	25920.00	10.00	0.00	0.00	Card	5184.00	2025-10-06 23:33:18.829019+05:30
177	\N	23	8	2025-08-09	2025-08-14	Checked-In	28512.00	10.00	0.00	0.00	Online	14256.00	2025-10-06 23:33:18.829019+05:30
180	\N	27	8	2025-08-25	2025-08-27	Checked-Out	26400.00	10.00	0.00	0.00	BankTransfer	5280.00	2025-10-06 23:33:18.829019+05:30
182	\N	44	8	2025-08-30	2025-09-01	Checked-In	28512.00	10.00	0.00	0.00	Online	5702.40	2025-10-06 23:33:18.829019+05:30
186	\N	86	8	2025-09-14	2025-09-16	Checked-Out	26400.00	10.00	0.00	0.00	BankTransfer	5280.00	2025-10-06 23:33:18.829019+05:30
187	\N	108	8	2025-09-17	2025-09-19	Checked-In	26400.00	10.00	0.00	0.00	Cash	5280.00	2025-10-06 23:33:18.829019+05:30
188	\N	89	8	2025-09-21	2025-09-26	Checked-Out	26400.00	10.00	0.00	0.00	Cash	13200.00	2025-10-06 23:33:18.829019+05:30
190	\N	32	9	2025-07-01	2025-07-05	Checked-Out	18000.00	10.00	0.00	0.00	Online	7200.00	2025-10-06 23:33:18.829019+05:30
192	\N	116	9	2025-07-12	2025-07-14	Checked-Out	19440.00	10.00	0.00	0.00	Cash	3888.00	2025-10-06 23:33:18.829019+05:30
193	\N	108	9	2025-07-14	2025-07-15	Checked-Out	18000.00	10.00	0.00	0.00	Cash	1800.00	2025-10-06 23:33:18.829019+05:30
194	\N	147	9	2025-07-15	2025-07-19	Checked-Out	18000.00	10.00	0.00	0.00	Cash	7200.00	2025-10-06 23:33:18.829019+05:30
196	\N	150	9	2025-07-26	2025-07-27	Checked-Out	19440.00	10.00	0.00	0.00	Cash	1944.00	2025-10-06 23:33:18.829019+05:30
197	\N	97	9	2025-07-28	2025-07-31	Checked-Out	18000.00	10.00	0.00	0.00	Cash	5400.00	2025-10-06 23:33:18.829019+05:30
199	\N	114	9	2025-08-06	2025-08-11	Checked-In	19800.00	10.00	0.00	0.00	Cash	9900.00	2025-10-06 23:33:18.829019+05:30
200	\N	46	9	2025-08-12	2025-08-17	Checked-Out	19800.00	10.00	0.00	0.00	Cash	9900.00	2025-10-06 23:33:18.829019+05:30
202	\N	92	9	2025-08-21	2025-08-26	Checked-Out	19800.00	10.00	0.00	0.00	Cash	9900.00	2025-10-06 23:33:18.829019+05:30
204	\N	67	9	2025-09-02	2025-09-04	Checked-Out	19800.00	10.00	0.00	0.00	Cash	3960.00	2025-10-06 23:33:18.829019+05:30
205	\N	92	9	2025-09-04	2025-09-09	Checked-Out	19800.00	10.00	0.00	0.00	BankTransfer	9900.00	2025-10-06 23:33:18.829019+05:30
212	\N	55	10	2025-07-07	2025-07-09	Checked-Out	18000.00	10.00	0.00	0.00	Online	3600.00	2025-10-06 23:33:18.829019+05:30
213	\N	120	10	2025-07-11	2025-07-16	Checked-Out	19440.00	10.00	0.00	0.00	BankTransfer	9720.00	2025-10-06 23:33:18.829019+05:30
214	\N	58	10	2025-07-16	2025-07-17	Checked-In	18000.00	10.00	0.00	0.00	Cash	1800.00	2025-10-06 23:33:18.829019+05:30
216	\N	64	10	2025-07-23	2025-07-25	Checked-Out	18000.00	10.00	0.00	0.00	Card	3600.00	2025-10-06 23:33:18.829019+05:30
221	\N	12	10	2025-08-07	2025-08-10	Checked-Out	19800.00	10.00	0.00	0.00	Card	5940.00	2025-10-06 23:33:18.829019+05:30
224	\N	135	10	2025-08-17	2025-08-20	Checked-In	19800.00	10.00	0.00	0.00	Cash	5940.00	2025-10-06 23:33:18.829019+05:30
226	\N	2	10	2025-08-22	2025-08-25	Checked-Out	21384.00	10.00	0.00	0.00	Online	6415.20	2025-10-06 23:33:18.829019+05:30
229	\N	68	10	2025-08-31	2025-09-03	Checked-In	19800.00	10.00	0.00	0.00	Card	5940.00	2025-10-06 23:33:18.829019+05:30
230	\N	75	10	2025-09-04	2025-09-06	Checked-In	19800.00	10.00	0.00	0.00	Cash	3960.00	2025-10-06 23:33:18.829019+05:30
231	\N	24	10	2025-09-06	2025-09-11	Checked-In	21384.00	10.00	0.00	0.00	Card	10692.00	2025-10-06 23:33:18.829019+05:30
235	\N	24	10	2025-09-21	2025-09-25	Checked-Out	19800.00	10.00	0.00	0.00	Cash	7920.00	2025-10-06 23:33:18.829019+05:30
236	\N	72	10	2025-09-25	2025-09-28	Checked-In	19800.00	10.00	0.00	0.00	Online	5940.00	2025-10-06 23:33:18.829019+05:30
240	\N	37	11	2025-07-09	2025-07-11	Checked-Out	18000.00	10.00	0.00	0.00	Cash	3600.00	2025-10-06 23:33:18.829019+05:30
241	\N	92	11	2025-07-13	2025-07-17	Checked-Out	18000.00	10.00	0.00	0.00	Online	7200.00	2025-10-06 23:33:18.829019+05:30
244	\N	43	11	2025-07-27	2025-08-01	Checked-Out	18000.00	10.00	0.00	0.00	BankTransfer	9000.00	2025-10-06 23:33:18.829019+05:30
179	\N	146	8	2025-08-20	2025-08-24	Checked-Out	26400.00	10.00	4457.34	0.00	Cash	10560.00	2025-10-06 23:33:18.829019+05:30
207	\N	40	9	2025-09-10	2025-09-14	Checked-In	19800.00	10.00	2302.67	0.00	Cash	7920.00	2025-10-06 23:33:18.829019+05:30
167	\N	31	8	2025-07-01	2025-07-04	Checked-Out	24000.00	10.00	2948.06	0.00	Online	7200.00	2025-10-06 23:33:18.829019+05:30
222	\N	39	10	2025-08-11	2025-08-13	Checked-Out	19800.00	10.00	2016.23	0.00	Online	3960.00	2025-10-06 23:33:18.829019+05:30
168	\N	87	8	2025-07-05	2025-07-09	Checked-Out	25920.00	10.00	4412.13	0.00	Online	10368.00	2025-10-06 23:33:18.829019+05:30
171	\N	139	8	2025-07-18	2025-07-22	Checked-Out	25920.00	10.00	4210.10	0.00	Online	10368.00	2025-10-06 23:33:18.829019+05:30
201	\N	122	9	2025-08-18	2025-08-20	Checked-Out	19800.00	10.00	3354.36	0.00	Online	3960.00	2025-10-06 23:33:18.829019+05:30
208	\N	45	9	2025-09-16	2025-09-19	Checked-Out	19800.00	10.00	3900.09	0.00	Cash	5940.00	2025-10-06 23:33:18.829019+05:30
223	\N	141	10	2025-08-14	2025-08-16	Checked-Out	19800.00	10.00	1468.82	0.00	Card	3960.00	2025-10-06 23:33:18.829019+05:30
181	\N	78	8	2025-08-27	2025-08-28	Cancelled	26400.00	10.00	0.00	0.00	Cash	2640.00	2025-10-06 23:33:18.829019+05:30
174	\N	42	8	2025-07-28	2025-07-30	Checked-Out	24000.00	10.00	2948.06	0.00	Online	4800.00	2025-10-06 23:33:18.829019+05:30
178	\N	129	8	2025-08-16	2025-08-19	Checked-Out	28512.00	10.00	3502.30	0.00	Card	8553.60	2025-10-06 23:33:18.829019+05:30
191	\N	150	9	2025-07-06	2025-07-10	Checked-Out	18000.00	10.00	2211.05	0.00	Cash	7200.00	2025-10-06 23:33:18.829019+05:30
203	\N	29	9	2025-08-27	2025-08-31	Checked-In	19800.00	10.00	2432.15	0.00	Online	7920.00	2025-10-06 23:33:18.829019+05:30
227	\N	86	10	2025-08-25	2025-08-27	Checked-Out	19800.00	10.00	2432.15	0.00	Card	3960.00	2025-10-06 23:33:18.829019+05:30
242	\N	98	11	2025-07-19	2025-07-23	Checked-Out	19440.00	10.00	2387.93	0.00	Cash	7776.00	2025-10-06 23:33:18.829019+05:30
195	\N	40	9	2025-07-20	2025-07-25	Cancelled	18000.00	10.00	0.00	0.00	BankTransfer	9000.00	2025-10-06 23:33:18.829019+05:30
211	\N	49	10	2025-07-01	2025-07-06	Cancelled	18000.00	10.00	0.00	0.00	Online	9000.00	2025-10-06 23:33:18.829019+05:30
245	\N	12	11	2025-08-02	2025-08-03	Cancelled	21384.00	10.00	0.00	0.00	Online	2138.40	2025-10-06 23:33:18.829019+05:30
165	\N	60	7	2025-09-26	2025-09-30	Checked-Out	28512.00	10.00	0.00	3833.98	Cash	11404.80	2025-10-06 23:33:18.829019+05:30
350	\N	78	15	2025-09-23	2025-09-24	Checked-In	19800.00	10.00	0.00	0.00	Cash	1980.00	2025-10-06 23:33:18.829019+05:30
176	\N	52	8	2025-08-05	2025-08-08	Checked-Out	26400.00	10.00	0.00	6486.33	Online	7920.00	2025-10-06 23:33:18.829019+05:30
209	\N	120	9	2025-09-20	2025-09-24	Checked-Out	21384.00	10.00	0.00	3511.61	Card	8553.60	2025-10-06 23:33:18.829019+05:30
218	\N	47	10	2025-07-30	2025-08-01	Checked-In	18000.00	10.00	0.00	4695.79	Cash	3600.00	2025-10-06 23:33:18.829019+05:30
219	\N	21	10	2025-08-01	2025-08-03	Checked-Out	21384.00	10.00	0.00	3751.19	Online	4276.80	2025-10-06 23:33:18.829019+05:30
220	\N	64	10	2025-08-05	2025-08-07	Checked-Out	19800.00	10.00	0.00	5101.29	Online	3960.00	2025-10-06 23:33:18.829019+05:30
228	\N	36	10	2025-08-28	2025-08-30	Checked-Out	19800.00	10.00	0.00	3799.20	Online	3960.00	2025-10-06 23:33:18.829019+05:30
206	\N	42	9	2025-09-09	2025-09-10	Checked-Out	19800.00	10.00	1350.10	5022.93	Online	1980.00	2025-10-06 23:33:18.829019+05:30
215	\N	35	10	2025-07-19	2025-07-22	Checked-Out	19440.00	10.00	2920.71	3409.81	Online	5832.00	2025-10-06 23:33:18.829019+05:30
172	\N	140	8	2025-07-24	2025-07-26	Checked-Out	24000.00	10.00	2948.06	7120.43	Cash	4800.00	2025-10-06 23:33:18.829019+05:30
246	\N	96	11	2025-08-03	2025-08-05	Checked-Out	19800.00	10.00	0.00	0.00	Online	3960.00	2025-10-06 23:33:18.829019+05:30
249	\N	7	11	2025-08-13	2025-08-15	Checked-Out	19800.00	10.00	0.00	0.00	Cash	3960.00	2025-10-06 23:33:18.829019+05:30
251	\N	137	11	2025-08-18	2025-08-21	Checked-In	19800.00	10.00	0.00	0.00	BankTransfer	5940.00	2025-10-06 23:33:18.829019+05:30
252	\N	149	11	2025-08-21	2025-08-25	Checked-Out	19800.00	10.00	0.00	0.00	BankTransfer	7920.00	2025-10-06 23:33:18.829019+05:30
255	\N	95	11	2025-09-05	2025-09-08	Checked-Out	21384.00	10.00	0.00	0.00	Cash	6415.20	2025-10-06 23:33:18.829019+05:30
256	\N	87	11	2025-09-08	2025-09-13	Checked-In	19800.00	10.00	0.00	0.00	Cash	9900.00	2025-10-06 23:33:18.829019+05:30
259	\N	91	11	2025-09-22	2025-09-25	Checked-Out	19800.00	10.00	0.00	0.00	BankTransfer	5940.00	2025-10-06 23:33:18.829019+05:30
260	\N	76	11	2025-09-25	2025-09-29	Checked-In	19800.00	10.00	0.00	0.00	Cash	7920.00	2025-10-06 23:33:18.829019+05:30
262	\N	127	12	2025-07-01	2025-07-03	Checked-Out	18000.00	10.00	0.00	0.00	Card	3600.00	2025-10-06 23:33:18.829019+05:30
263	\N	30	12	2025-07-04	2025-07-09	Checked-Out	19440.00	10.00	0.00	0.00	Online	9720.00	2025-10-06 23:33:18.829019+05:30
264	\N	29	12	2025-07-10	2025-07-12	Checked-Out	18000.00	10.00	0.00	0.00	Card	3600.00	2025-10-06 23:33:18.829019+05:30
273	\N	1	12	2025-08-13	2025-08-15	Checked-In	19800.00	10.00	0.00	0.00	Cash	3960.00	2025-10-06 23:33:18.829019+05:30
274	\N	134	12	2025-08-15	2025-08-19	Checked-Out	21384.00	10.00	0.00	0.00	Card	8553.60	2025-10-06 23:33:18.829019+05:30
275	\N	69	12	2025-08-19	2025-08-22	Checked-Out	19800.00	10.00	0.00	0.00	Online	5940.00	2025-10-06 23:33:18.829019+05:30
276	\N	121	12	2025-08-24	2025-08-27	Checked-Out	19800.00	10.00	0.00	0.00	Online	5940.00	2025-10-06 23:33:18.829019+05:30
278	\N	148	12	2025-08-29	2025-08-31	Checked-Out	21384.00	10.00	0.00	0.00	Online	4276.80	2025-10-06 23:33:18.829019+05:30
279	\N	32	12	2025-08-31	2025-09-05	Checked-In	19800.00	10.00	0.00	0.00	Online	9900.00	2025-10-06 23:33:18.829019+05:30
280	\N	105	12	2025-09-05	2025-09-09	Checked-Out	21384.00	10.00	0.00	0.00	Online	8553.60	2025-10-06 23:33:18.829019+05:30
285	\N	27	12	2025-09-30	2025-10-03	Checked-Out	19800.00	10.00	0.00	0.00	Card	5940.00	2025-10-06 23:33:18.829019+05:30
286	\N	31	13	2025-07-01	2025-07-02	Checked-In	18000.00	10.00	0.00	0.00	Cash	1800.00	2025-10-06 23:33:18.829019+05:30
290	\N	131	13	2025-07-15	2025-07-20	Checked-Out	18000.00	10.00	0.00	0.00	Online	9000.00	2025-10-06 23:33:18.829019+05:30
291	\N	105	13	2025-07-21	2025-07-25	Checked-Out	18000.00	10.00	0.00	0.00	Card	7200.00	2025-10-06 23:33:18.829019+05:30
295	\N	38	13	2025-08-10	2025-08-15	Checked-Out	19800.00	10.00	0.00	0.00	Card	9900.00	2025-10-06 23:33:18.829019+05:30
296	\N	115	13	2025-08-16	2025-08-19	Checked-Out	21384.00	10.00	0.00	0.00	Card	6415.20	2025-10-06 23:33:18.829019+05:30
297	\N	6	13	2025-08-19	2025-08-22	Checked-In	19800.00	10.00	0.00	0.00	Online	5940.00	2025-10-06 23:33:18.829019+05:30
302	\N	36	13	2025-09-06	2025-09-10	Checked-Out	21384.00	10.00	0.00	0.00	Card	8553.60	2025-10-06 23:33:18.829019+05:30
303	\N	92	13	2025-09-10	2025-09-14	Checked-Out	19800.00	10.00	0.00	0.00	Cash	7920.00	2025-10-06 23:33:18.829019+05:30
305	\N	88	13	2025-09-22	2025-09-26	Checked-In	19800.00	10.00	0.00	0.00	Online	7920.00	2025-10-06 23:33:18.829019+05:30
306	\N	132	13	2025-09-27	2025-09-28	Checked-Out	21384.00	10.00	0.00	0.00	Online	2138.40	2025-10-06 23:33:18.829019+05:30
308	\N	45	14	2025-07-01	2025-07-06	Checked-Out	18000.00	10.00	0.00	0.00	Cash	9000.00	2025-10-06 23:33:18.829019+05:30
309	\N	44	14	2025-07-07	2025-07-11	Checked-Out	18000.00	10.00	0.00	0.00	Online	7200.00	2025-10-06 23:33:18.829019+05:30
311	\N	79	14	2025-07-16	2025-07-20	Checked-Out	18000.00	10.00	0.00	0.00	Cash	7200.00	2025-10-06 23:33:18.829019+05:30
313	\N	34	14	2025-07-27	2025-07-29	Checked-In	18000.00	10.00	0.00	0.00	Cash	3600.00	2025-10-06 23:33:18.829019+05:30
315	\N	108	14	2025-08-06	2025-08-10	Checked-Out	19800.00	10.00	0.00	0.00	Online	7920.00	2025-10-06 23:33:18.829019+05:30
317	\N	20	14	2025-08-13	2025-08-17	Checked-In	19800.00	10.00	0.00	0.00	Cash	7920.00	2025-10-06 23:33:18.829019+05:30
320	\N	20	14	2025-08-27	2025-08-30	Checked-Out	19800.00	10.00	0.00	0.00	Online	5940.00	2025-10-06 23:33:18.829019+05:30
323	\N	69	14	2025-09-12	2025-09-15	Checked-In	21384.00	10.00	0.00	0.00	BankTransfer	6415.20	2025-10-06 23:33:18.829019+05:30
324	\N	141	14	2025-09-16	2025-09-19	Checked-Out	19800.00	10.00	0.00	0.00	BankTransfer	5940.00	2025-10-06 23:33:18.829019+05:30
247	\N	108	11	2025-08-06	2025-08-10	Checked-Out	19800.00	10.00	2348.40	0.00	Card	7920.00	2025-10-06 23:33:18.829019+05:30
258	\N	83	11	2025-09-19	2025-09-22	Checked-Out	21384.00	10.00	1854.52	0.00	Online	6415.20	2025-10-06 23:33:18.829019+05:30
283	\N	42	12	2025-09-19	2025-09-24	Checked-Out	21384.00	10.00	4011.40	0.00	BankTransfer	10692.00	2025-10-06 23:33:18.829019+05:30
299	\N	129	13	2025-08-28	2025-08-29	Checked-Out	19800.00	10.00	1437.64	0.00	Card	1980.00	2025-10-06 23:33:18.829019+05:30
319	\N	54	14	2025-08-24	2025-08-27	Checked-In	19800.00	10.00	2728.37	0.00	Card	5940.00	2025-10-06 23:33:18.829019+05:30
248	\N	57	11	2025-08-10	2025-08-12	Checked-Out	19800.00	10.00	2432.15	0.00	Online	3960.00	2025-10-06 23:33:18.829019+05:30
250	\N	4	11	2025-08-16	2025-08-17	Checked-Out	21384.00	10.00	2626.72	0.00	BankTransfer	2138.40	2025-10-06 23:33:18.829019+05:30
267	\N	50	12	2025-07-19	2025-07-23	Checked-Out	19440.00	10.00	2387.93	0.00	Cash	7776.00	2025-10-06 23:33:18.829019+05:30
269	\N	80	12	2025-07-29	2025-08-01	Checked-Out	18000.00	10.00	2211.05	0.00	Cash	5400.00	2025-10-06 23:33:18.829019+05:30
277	\N	83	12	2025-08-27	2025-08-29	Checked-Out	19800.00	10.00	2432.15	0.00	Cash	3960.00	2025-10-06 23:33:18.829019+05:30
281	\N	56	12	2025-09-11	2025-09-15	Checked-Out	19800.00	10.00	2432.15	0.00	Card	7920.00	2025-10-06 23:33:18.829019+05:30
282	\N	147	12	2025-09-16	2025-09-18	Checked-Out	19800.00	10.00	2432.15	0.00	Card	3960.00	2025-10-06 23:33:18.829019+05:30
322	\N	36	14	2025-09-06	2025-09-10	Checked-Out	21384.00	10.00	2626.72	0.00	BankTransfer	8553.60	2025-10-06 23:33:18.829019+05:30
253	\N	107	11	2025-08-27	2025-08-29	Cancelled	19800.00	10.00	0.00	0.00	Online	3960.00	2025-10-06 23:33:18.829019+05:30
288	\N	82	13	2025-07-09	2025-07-11	Cancelled	18000.00	10.00	0.00	0.00	BankTransfer	3600.00	2025-10-06 23:33:18.829019+05:30
321	\N	42	14	2025-08-31	2025-09-04	Cancelled	19800.00	10.00	0.00	0.00	BankTransfer	7920.00	2025-10-06 23:33:18.829019+05:30
268	\N	10	12	2025-07-24	2025-07-29	Checked-Out	18000.00	10.00	0.00	3651.80	Cash	9000.00	2025-10-06 23:33:18.829019+05:30
287	\N	150	13	2025-07-03	2025-07-07	Checked-Out	18000.00	10.00	0.00	4331.16	Cash	7200.00	2025-10-06 23:33:18.829019+05:30
430	\N	67	19	2025-07-24	2025-07-27	Checked-Out	12000.00	10.00	0.00	0.00	BankTransfer	3600.00	2025-10-06 23:33:18.829019+05:30
432	\N	107	19	2025-07-30	2025-08-01	Checked-Out	12000.00	10.00	0.00	0.00	Cash	2400.00	2025-10-06 23:33:18.829019+05:30
433	\N	110	19	2025-08-01	2025-08-05	Checked-Out	14256.00	10.00	0.00	0.00	Card	5702.40	2025-10-06 23:33:18.829019+05:30
437	\N	56	19	2025-08-15	2025-08-17	Checked-In	14256.00	10.00	0.00	0.00	Cash	2851.20	2025-10-06 23:33:18.829019+05:30
289	\N	12	13	2025-07-13	2025-07-14	Checked-In	18000.00	10.00	0.00	1838.02	Card	1800.00	2025-10-06 23:33:18.829019+05:30
292	\N	48	13	2025-07-25	2025-07-30	Checked-Out	19440.00	10.00	0.00	4660.88	Online	9720.00	2025-10-06 23:33:18.829019+05:30
307	\N	2	13	2025-09-30	2025-10-03	Checked-In	19800.00	10.00	0.00	2460.96	Cash	5940.00	2025-10-06 23:33:18.829019+05:30
310	\N	3	14	2025-07-11	2025-07-15	Checked-Out	19440.00	10.00	0.00	2411.96	Cash	7776.00	2025-10-06 23:33:18.829019+05:30
318	\N	13	14	2025-08-19	2025-08-22	Checked-Out	19800.00	10.00	0.00	2846.71	BankTransfer	5940.00	2025-10-06 23:33:18.829019+05:30
261	\N	90	11	2025-09-30	2025-10-03	Checked-Out	19800.00	10.00	2090.63	2458.19	BankTransfer	5940.00	2025-10-06 23:33:18.829019+05:30
266	\N	126	12	2025-07-14	2025-07-17	Checked-Out	18000.00	10.00	1457.14	2295.35	BankTransfer	5400.00	2025-10-06 23:33:18.829019+05:30
257	\N	99	11	2025-09-14	2025-09-17	Checked-Out	19800.00	10.00	2432.15	2976.88	Cash	5940.00	2025-10-06 23:33:18.829019+05:30
328	\N	139	15	2025-07-01	2025-07-03	Checked-Out	18000.00	10.00	0.00	0.00	Online	3600.00	2025-10-06 23:33:18.829019+05:30
329	\N	55	15	2025-07-04	2025-07-08	Checked-Out	19440.00	10.00	0.00	0.00	Cash	7776.00	2025-10-06 23:33:18.829019+05:30
331	\N	117	15	2025-07-13	2025-07-18	Checked-Out	18000.00	10.00	0.00	0.00	Online	9000.00	2025-10-06 23:33:18.829019+05:30
332	\N	137	15	2025-07-19	2025-07-22	Checked-Out	19440.00	10.00	0.00	0.00	Cash	5832.00	2025-10-06 23:33:18.829019+05:30
333	\N	135	15	2025-07-23	2025-07-26	Checked-Out	18000.00	10.00	0.00	0.00	Cash	5400.00	2025-10-06 23:33:18.829019+05:30
334	\N	118	15	2025-07-26	2025-07-28	Checked-Out	19440.00	10.00	0.00	0.00	Card	3888.00	2025-10-06 23:33:18.829019+05:30
335	\N	138	15	2025-07-30	2025-07-31	Checked-Out	18000.00	10.00	0.00	0.00	Cash	1800.00	2025-10-06 23:33:18.829019+05:30
336	\N	79	15	2025-08-02	2025-08-06	Checked-Out	21384.00	10.00	0.00	0.00	Online	8553.60	2025-10-06 23:33:18.829019+05:30
337	\N	68	15	2025-08-07	2025-08-08	Checked-Out	19800.00	10.00	0.00	0.00	Online	1980.00	2025-10-06 23:33:18.829019+05:30
338	\N	54	15	2025-08-08	2025-08-10	Checked-Out	21384.00	10.00	0.00	0.00	Online	4276.80	2025-10-06 23:33:18.829019+05:30
340	\N	149	15	2025-08-13	2025-08-15	Checked-Out	19800.00	10.00	0.00	0.00	BankTransfer	3960.00	2025-10-06 23:33:18.829019+05:30
342	\N	53	15	2025-08-22	2025-08-23	Checked-Out	21384.00	10.00	0.00	0.00	Cash	2138.40	2025-10-06 23:33:18.829019+05:30
345	\N	6	15	2025-09-01	2025-09-05	Checked-Out	19800.00	10.00	0.00	0.00	Online	7920.00	2025-10-06 23:33:18.829019+05:30
347	\N	81	15	2025-09-10	2025-09-15	Checked-Out	19800.00	10.00	0.00	0.00	Card	9900.00	2025-10-06 23:33:18.829019+05:30
351	\N	79	15	2025-09-24	2025-09-27	Checked-In	19800.00	10.00	0.00	0.00	Cash	5940.00	2025-10-06 23:33:18.829019+05:30
352	\N	55	15	2025-09-27	2025-09-29	Checked-Out	21384.00	10.00	0.00	0.00	BankTransfer	4276.80	2025-10-06 23:33:18.829019+05:30
353	\N	108	15	2025-09-29	2025-10-02	Checked-Out	19800.00	10.00	0.00	0.00	Online	5940.00	2025-10-06 23:33:18.829019+05:30
354	\N	147	16	2025-07-01	2025-07-04	Checked-Out	12000.00	10.00	0.00	0.00	Online	3600.00	2025-10-06 23:33:18.829019+05:30
355	\N	74	16	2025-07-05	2025-07-08	Checked-Out	12960.00	10.00	0.00	0.00	Card	3888.00	2025-10-06 23:33:18.829019+05:30
357	\N	55	16	2025-07-12	2025-07-14	Checked-Out	12960.00	10.00	0.00	0.00	BankTransfer	2592.00	2025-10-06 23:33:18.829019+05:30
358	\N	59	16	2025-07-15	2025-07-18	Checked-Out	12000.00	10.00	0.00	0.00	Online	3600.00	2025-10-06 23:33:18.829019+05:30
360	\N	92	16	2025-07-23	2025-07-27	Checked-Out	12000.00	10.00	0.00	0.00	Card	4800.00	2025-10-06 23:33:18.829019+05:30
363	\N	47	16	2025-08-04	2025-08-06	Checked-Out	13200.00	10.00	0.00	0.00	Cash	2640.00	2025-10-06 23:33:18.829019+05:30
364	\N	32	16	2025-08-08	2025-08-10	Checked-In	14256.00	10.00	0.00	0.00	Cash	2851.20	2025-10-06 23:33:18.829019+05:30
367	\N	62	16	2025-08-17	2025-08-19	Checked-Out	13200.00	10.00	0.00	0.00	Card	2640.00	2025-10-06 23:33:18.829019+05:30
369	\N	98	16	2025-08-26	2025-08-31	Checked-Out	13200.00	10.00	0.00	0.00	Cash	6600.00	2025-10-06 23:33:18.829019+05:30
371	\N	88	16	2025-09-05	2025-09-07	Checked-Out	14256.00	10.00	0.00	0.00	Cash	2851.20	2025-10-06 23:33:18.829019+05:30
372	\N	35	16	2025-09-08	2025-09-10	Checked-Out	13200.00	10.00	0.00	0.00	Card	2640.00	2025-10-06 23:33:18.829019+05:30
373	\N	14	16	2025-09-12	2025-09-14	Checked-Out	14256.00	10.00	0.00	0.00	BankTransfer	2851.20	2025-10-06 23:33:18.829019+05:30
374	\N	123	16	2025-09-15	2025-09-16	Checked-Out	13200.00	10.00	0.00	0.00	Cash	1320.00	2025-10-06 23:33:18.829019+05:30
375	\N	38	16	2025-09-18	2025-09-21	Checked-Out	13200.00	10.00	0.00	0.00	Cash	3960.00	2025-10-06 23:33:18.829019+05:30
376	\N	11	16	2025-09-21	2025-09-24	Checked-Out	13200.00	10.00	0.00	0.00	Cash	3960.00	2025-10-06 23:33:18.829019+05:30
378	\N	63	16	2025-09-28	2025-10-02	Checked-Out	13200.00	10.00	0.00	0.00	Online	5280.00	2025-10-06 23:33:18.829019+05:30
380	\N	9	17	2025-07-04	2025-07-05	Checked-Out	12960.00	10.00	0.00	0.00	Cash	1296.00	2025-10-06 23:33:18.829019+05:30
381	\N	47	17	2025-07-05	2025-07-10	Checked-Out	12960.00	10.00	0.00	0.00	Cash	6480.00	2025-10-06 23:33:18.829019+05:30
384	\N	17	17	2025-07-19	2025-07-24	Checked-Out	12960.00	10.00	0.00	0.00	Online	6480.00	2025-10-06 23:33:18.829019+05:30
385	\N	129	17	2025-07-24	2025-07-27	Checked-Out	12000.00	10.00	0.00	0.00	Online	3600.00	2025-10-06 23:33:18.829019+05:30
387	\N	89	17	2025-07-31	2025-08-05	Checked-In	12000.00	10.00	0.00	0.00	Card	6000.00	2025-10-06 23:33:18.829019+05:30
390	\N	144	17	2025-08-15	2025-08-19	Checked-Out	14256.00	10.00	0.00	0.00	Cash	5702.40	2025-10-06 23:33:18.829019+05:30
392	\N	14	17	2025-08-25	2025-08-29	Checked-Out	13200.00	10.00	0.00	0.00	Online	5280.00	2025-10-06 23:33:18.829019+05:30
393	\N	69	17	2025-08-30	2025-09-03	Checked-Out	14256.00	10.00	0.00	0.00	Cash	5702.40	2025-10-06 23:33:18.829019+05:30
394	\N	126	17	2025-09-04	2025-09-08	Checked-Out	13200.00	10.00	0.00	0.00	Card	5280.00	2025-10-06 23:33:18.829019+05:30
397	\N	36	17	2025-09-15	2025-09-17	Checked-Out	13200.00	10.00	0.00	0.00	Online	2640.00	2025-10-06 23:33:18.829019+05:30
398	\N	55	17	2025-09-19	2025-09-21	Checked-In	14256.00	10.00	0.00	0.00	BankTransfer	2851.20	2025-10-06 23:33:18.829019+05:30
399	\N	118	17	2025-09-22	2025-09-27	Checked-Out	13200.00	10.00	0.00	0.00	Card	6600.00	2025-10-06 23:33:18.829019+05:30
400	\N	89	17	2025-09-27	2025-10-01	Checked-Out	14256.00	10.00	0.00	0.00	Online	5702.40	2025-10-06 23:33:18.829019+05:30
401	\N	68	18	2025-07-01	2025-07-03	Checked-In	12000.00	10.00	0.00	0.00	Card	2400.00	2025-10-06 23:33:18.829019+05:30
402	\N	59	18	2025-07-05	2025-07-07	Checked-In	12960.00	10.00	0.00	0.00	Online	2592.00	2025-10-06 23:33:18.829019+05:30
403	\N	112	18	2025-07-09	2025-07-10	Checked-Out	12000.00	10.00	0.00	0.00	Online	1200.00	2025-10-06 23:33:18.829019+05:30
407	\N	39	18	2025-07-25	2025-07-29	Checked-In	12960.00	10.00	0.00	0.00	Online	5184.00	2025-10-06 23:33:18.829019+05:30
349	\N	56	15	2025-09-18	2025-09-21	Checked-Out	19800.00	10.00	3836.12	0.00	Cash	5940.00	2025-10-06 23:33:18.829019+05:30
359	\N	9	16	2025-07-19	2025-07-22	Checked-Out	12960.00	10.00	1399.83	0.00	Online	3888.00	2025-10-06 23:33:18.829019+05:30
382	\N	67	17	2025-07-12	2025-07-14	Checked-Out	12960.00	10.00	2272.46	0.00	Cash	2592.00	2025-10-06 23:33:18.829019+05:30
362	\N	40	16	2025-07-31	2025-08-03	Cancelled	12000.00	10.00	0.00	0.00	BankTransfer	3600.00	2025-10-06 23:33:18.829019+05:30
379	\N	23	17	2025-07-01	2025-07-03	Checked-In	12000.00	10.00	1126.09	0.00	BankTransfer	2400.00	2025-10-06 23:33:18.829019+05:30
386	\N	75	17	2025-07-27	2025-07-30	Checked-Out	12000.00	10.00	1557.65	0.00	BankTransfer	3600.00	2025-10-06 23:33:18.829019+05:30
404	\N	76	18	2025-07-10	2025-07-12	Checked-Out	12000.00	10.00	605.85	0.00	BankTransfer	2400.00	2025-10-06 23:33:18.829019+05:30
341	\N	124	15	2025-08-17	2025-08-21	Checked-Out	19800.00	10.00	2432.15	0.00	Online	7920.00	2025-10-06 23:33:18.829019+05:30
343	\N	42	15	2025-08-24	2025-08-26	Checked-Out	19800.00	10.00	2432.15	0.00	Online	3960.00	2025-10-06 23:33:18.829019+05:30
344	\N	148	15	2025-08-28	2025-08-30	Checked-In	19800.00	10.00	0.00	3555.34	Cash	3960.00	2025-10-06 23:33:18.829019+05:30
388	\N	25	17	2025-08-07	2025-08-11	Checked-Out	13200.00	10.00	1621.43	0.00	BankTransfer	5280.00	2025-10-06 23:33:18.829019+05:30
391	\N	57	17	2025-08-19	2025-08-23	Checked-Out	13200.00	10.00	1621.43	0.00	Online	5280.00	2025-10-06 23:33:18.829019+05:30
330	\N	2	15	2025-07-09	2025-07-13	Checked-In	18000.00	10.00	2211.05	0.00	Cash	7200.00	2025-10-06 23:33:18.829019+05:30
389	\N	66	17	2025-08-11	2025-08-14	Cancelled	13200.00	10.00	0.00	0.00	Cash	3960.00	2025-10-06 23:33:18.829019+05:30
368	\N	34	16	2025-08-21	2025-08-26	Cancelled	13200.00	10.00	1621.43	0.00	Online	6600.00	2025-10-06 23:33:18.829019+05:30
370	\N	127	16	2025-09-01	2025-09-05	Checked-In	13200.00	10.00	0.00	2054.59	Cash	5280.00	2025-10-06 23:33:18.829019+05:30
406	\N	139	18	2025-07-20	2025-07-24	Checked-Out	12000.00	10.00	0.00	3362.99	BankTransfer	4800.00	2025-10-06 23:33:18.829019+05:30
346	\N	59	15	2025-09-06	2025-09-09	Checked-Out	21384.00	10.00	1618.29	5888.78	Online	6415.20	2025-10-06 23:33:18.829019+05:30
395	\N	69	17	2025-09-09	2025-09-12	Checked-In	13200.00	10.00	1355.09	2298.51	Card	3960.00	2025-10-06 23:33:18.829019+05:30
356	\N	138	16	2025-07-08	2025-07-12	Checked-Out	12000.00	10.00	1474.03	2022.86	Cash	4800.00	2025-10-06 23:33:18.829019+05:30
409	\N	109	18	2025-08-03	2025-08-06	Checked-In	13200.00	10.00	0.00	0.00	Card	3960.00	2025-10-06 23:33:18.829019+05:30
411	\N	32	18	2025-08-11	2025-08-15	Checked-Out	13200.00	10.00	0.00	0.00	Card	5280.00	2025-10-06 23:33:18.829019+05:30
412	\N	4	18	2025-08-16	2025-08-20	Checked-Out	14256.00	10.00	0.00	0.00	BankTransfer	5702.40	2025-10-06 23:33:18.829019+05:30
413	\N	80	18	2025-08-21	2025-08-22	Checked-Out	13200.00	10.00	0.00	0.00	Card	1320.00	2025-10-06 23:33:18.829019+05:30
415	\N	21	18	2025-08-29	2025-09-02	Checked-In	14256.00	10.00	0.00	0.00	BankTransfer	5702.40	2025-10-06 23:33:18.829019+05:30
416	\N	87	18	2025-09-04	2025-09-06	Checked-In	13200.00	10.00	0.00	0.00	BankTransfer	2640.00	2025-10-06 23:33:18.829019+05:30
417	\N	141	18	2025-09-07	2025-09-09	Checked-Out	13200.00	10.00	0.00	0.00	Card	2640.00	2025-10-06 23:33:18.829019+05:30
420	\N	145	18	2025-09-19	2025-09-20	Checked-In	14256.00	10.00	0.00	0.00	Cash	1425.60	2025-10-06 23:33:18.829019+05:30
421	\N	142	18	2025-09-20	2025-09-25	Checked-Out	14256.00	10.00	0.00	0.00	BankTransfer	7128.00	2025-10-06 23:33:18.829019+05:30
422	\N	32	18	2025-09-27	2025-09-29	Checked-Out	14256.00	10.00	0.00	0.00	Cash	2851.20	2025-10-06 23:33:18.829019+05:30
423	\N	48	18	2025-09-29	2025-10-03	Checked-Out	13200.00	10.00	0.00	0.00	Cash	5280.00	2025-10-06 23:33:18.829019+05:30
424	\N	37	19	2025-07-01	2025-07-03	Checked-Out	12000.00	10.00	0.00	0.00	Cash	2400.00	2025-10-06 23:33:18.829019+05:30
426	\N	26	19	2025-07-04	2025-07-09	Checked-Out	12960.00	10.00	0.00	0.00	BankTransfer	6480.00	2025-10-06 23:33:18.829019+05:30
427	\N	84	19	2025-07-10	2025-07-13	Checked-Out	12000.00	10.00	0.00	0.00	Card	3600.00	2025-10-06 23:33:18.829019+05:30
428	\N	145	19	2025-07-14	2025-07-18	Checked-Out	12000.00	10.00	0.00	0.00	Cash	4800.00	2025-10-06 23:33:18.829019+05:30
429	\N	134	19	2025-07-19	2025-07-23	Checked-In	12960.00	10.00	0.00	0.00	Cash	5184.00	2025-10-06 23:33:18.829019+05:30
441	\N	6	19	2025-08-27	2025-08-29	Checked-In	13200.00	10.00	0.00	0.00	Cash	2640.00	2025-10-06 23:33:18.829019+05:30
443	\N	47	19	2025-09-05	2025-09-07	Checked-Out	14256.00	10.00	0.00	0.00	Online	2851.20	2025-10-06 23:33:18.829019+05:30
445	\N	128	19	2025-09-12	2025-09-16	Checked-Out	14256.00	10.00	0.00	0.00	Cash	5702.40	2025-10-06 23:33:18.829019+05:30
447	\N	105	19	2025-09-21	2025-09-22	Checked-Out	13200.00	10.00	0.00	0.00	Online	1320.00	2025-10-06 23:33:18.829019+05:30
453	\N	85	20	2025-07-12	2025-07-14	Checked-Out	12960.00	10.00	0.00	0.00	BankTransfer	2592.00	2025-10-06 23:33:18.829019+05:30
454	\N	105	20	2025-07-14	2025-07-17	Checked-Out	12000.00	10.00	0.00	0.00	Cash	3600.00	2025-10-06 23:33:18.829019+05:30
456	\N	28	20	2025-07-24	2025-07-29	Checked-Out	12000.00	10.00	0.00	0.00	Cash	6000.00	2025-10-06 23:33:18.829019+05:30
457	\N	46	20	2025-07-30	2025-08-04	Checked-In	12000.00	10.00	0.00	0.00	Card	6000.00	2025-10-06 23:33:18.829019+05:30
458	\N	58	20	2025-08-06	2025-08-07	Checked-Out	13200.00	10.00	0.00	0.00	Online	1320.00	2025-10-06 23:33:18.829019+05:30
460	\N	89	20	2025-08-14	2025-08-16	Checked-Out	13200.00	10.00	0.00	0.00	Online	2640.00	2025-10-06 23:33:18.829019+05:30
465	\N	75	20	2025-09-02	2025-09-06	Checked-Out	13200.00	10.00	0.00	0.00	Online	5280.00	2025-10-06 23:33:18.829019+05:30
466	\N	85	20	2025-09-06	2025-09-10	Checked-Out	14256.00	10.00	0.00	0.00	Online	5702.40	2025-10-06 23:33:18.829019+05:30
467	\N	72	20	2025-09-12	2025-09-14	Checked-Out	14256.00	10.00	0.00	0.00	Cash	2851.20	2025-10-06 23:33:18.829019+05:30
468	\N	121	20	2025-09-16	2025-09-17	Checked-Out	13200.00	10.00	0.00	0.00	Cash	1320.00	2025-10-06 23:33:18.829019+05:30
469	\N	15	20	2025-09-18	2025-09-21	Checked-Out	13200.00	10.00	0.00	0.00	Online	3960.00	2025-10-06 23:33:18.829019+05:30
470	\N	111	20	2025-09-22	2025-09-26	Checked-Out	13200.00	10.00	0.00	0.00	Online	5280.00	2025-10-06 23:33:18.829019+05:30
472	\N	116	20	2025-09-29	2025-10-01	Checked-In	13200.00	10.00	0.00	0.00	Online	2640.00	2025-10-06 23:33:18.829019+05:30
474	\N	32	21	2025-07-05	2025-07-10	Checked-Out	43200.00	10.00	0.00	0.00	Card	21600.00	2025-10-06 23:33:18.829019+05:30
475	\N	114	21	2025-07-11	2025-07-13	Checked-Out	43200.00	10.00	0.00	0.00	BankTransfer	8640.00	2025-10-06 23:33:18.829019+05:30
476	\N	42	21	2025-07-14	2025-07-16	Checked-Out	40000.00	10.00	0.00	0.00	Card	8000.00	2025-10-06 23:33:18.829019+05:30
478	\N	68	21	2025-07-19	2025-07-23	Checked-In	43200.00	10.00	0.00	0.00	Cash	17280.00	2025-10-06 23:33:18.829019+05:30
479	\N	63	21	2025-07-25	2025-07-28	Checked-Out	43200.00	10.00	0.00	0.00	Card	12960.00	2025-10-06 23:33:18.829019+05:30
480	\N	119	21	2025-07-28	2025-07-30	Checked-Out	40000.00	10.00	0.00	0.00	Online	8000.00	2025-10-06 23:33:18.829019+05:30
482	\N	94	21	2025-08-05	2025-08-09	Checked-Out	44000.00	10.00	0.00	0.00	Cash	17600.00	2025-10-06 23:33:18.829019+05:30
483	\N	119	21	2025-08-11	2025-08-15	Checked-Out	44000.00	10.00	0.00	0.00	BankTransfer	17600.00	2025-10-06 23:33:18.829019+05:30
485	\N	146	21	2025-08-23	2025-08-28	Checked-Out	47520.00	10.00	0.00	0.00	BankTransfer	23760.00	2025-10-06 23:33:18.829019+05:30
487	\N	150	21	2025-09-03	2025-09-08	Checked-Out	44000.00	10.00	0.00	0.00	Cash	22000.00	2025-10-06 23:33:18.829019+05:30
434	\N	81	19	2025-08-07	2025-08-09	Checked-Out	13200.00	10.00	1754.27	0.00	Cash	2640.00	2025-10-06 23:33:18.829019+05:30
448	\N	113	19	2025-09-23	2025-09-28	Checked-Out	13200.00	10.00	1166.86	0.00	Cash	6600.00	2025-10-06 23:33:18.829019+05:30
450	\N	3	20	2025-07-01	2025-07-03	Checked-Out	12000.00	10.00	1418.72	0.00	Card	2400.00	2025-10-06 23:33:18.829019+05:30
451	\N	41	20	2025-07-04	2025-07-07	Checked-Out	12960.00	10.00	1515.03	0.00	Card	3888.00	2025-10-06 23:33:18.829019+05:30
414	\N	4	18	2025-08-23	2025-08-28	Checked-Out	14256.00	10.00	1190.87	0.00	Cash	7128.00	2025-10-06 23:33:18.829019+05:30
418	\N	128	18	2025-09-10	2025-09-11	Checked-Out	13200.00	10.00	1006.91	0.00	Online	1320.00	2025-10-06 23:33:18.829019+05:30
622	\N	53	27	2025-08-02	2025-08-07	Checked-In	28512.00	10.00	0.00	0.00	Cash	14256.00	2025-10-06 23:33:18.829019+05:30
625	\N	90	27	2025-08-18	2025-08-20	Checked-Out	26400.00	10.00	0.00	0.00	Online	5280.00	2025-10-06 23:33:18.829019+05:30
425	\N	118	19	2025-07-03	2025-07-04	Checked-Out	12000.00	10.00	1651.87	0.00	BankTransfer	1200.00	2025-10-06 23:33:18.829019+05:30
439	\N	22	19	2025-08-21	2025-08-22	Checked-In	13200.00	10.00	1943.48	0.00	Card	1320.00	2025-10-06 23:33:18.829019+05:30
440	\N	26	19	2025-08-23	2025-08-27	Checked-Out	14256.00	10.00	1972.69	0.00	BankTransfer	5702.40	2025-10-06 23:33:18.829019+05:30
410	\N	69	18	2025-08-06	2025-08-09	Checked-Out	13200.00	10.00	1621.43	0.00	Card	3960.00	2025-10-06 23:33:18.829019+05:30
446	\N	21	19	2025-09-18	2025-09-20	Checked-In	13200.00	10.00	1621.43	0.00	Cash	2640.00	2025-10-06 23:33:18.829019+05:30
449	\N	29	19	2025-09-29	2025-10-01	Checked-Out	13200.00	10.00	1621.43	0.00	Online	2640.00	2025-10-06 23:33:18.829019+05:30
455	\N	133	20	2025-07-18	2025-07-23	Checked-Out	12960.00	10.00	1591.95	0.00	BankTransfer	6480.00	2025-10-06 23:33:18.829019+05:30
461	\N	85	20	2025-08-18	2025-08-20	Checked-In	13200.00	10.00	1621.43	0.00	Online	2640.00	2025-10-06 23:33:18.829019+05:30
471	\N	45	20	2025-09-27	2025-09-28	Checked-Out	14256.00	10.00	1751.15	0.00	Online	1425.60	2025-10-06 23:33:18.829019+05:30
419	\N	85	18	2025-09-13	2025-09-17	Checked-Out	14256.00	10.00	0.00	3278.21	Cash	5702.40	2025-10-06 23:33:18.829019+05:30
408	\N	107	18	2025-07-30	2025-08-02	Cancelled	12000.00	10.00	0.00	0.00	BankTransfer	3600.00	2025-10-06 23:33:18.829019+05:30
444	\N	60	19	2025-09-07	2025-09-11	Cancelled	13200.00	10.00	0.00	0.00	Card	5280.00	2025-10-06 23:33:18.829019+05:30
473	\N	86	21	2025-07-01	2025-07-04	Cancelled	40000.00	10.00	0.00	0.00	BankTransfer	12000.00	2025-10-06 23:33:18.829019+05:30
481	\N	73	21	2025-08-01	2025-08-04	Cancelled	47520.00	10.00	0.00	0.00	Card	14256.00	2025-10-06 23:33:18.829019+05:30
484	\N	103	21	2025-08-16	2025-08-21	Cancelled	47520.00	10.00	5837.16	0.00	Cash	23760.00	2025-10-06 23:33:18.829019+05:30
464	\N	87	20	2025-08-31	2025-09-02	Checked-Out	13200.00	10.00	0.00	2468.98	Online	2640.00	2025-10-06 23:33:18.829019+05:30
431	\N	13	19	2025-07-27	2025-07-29	Checked-Out	12000.00	10.00	1467.92	1259.13	Card	2400.00	2025-10-06 23:33:18.829019+05:30
490	\N	140	21	2025-09-17	2025-09-20	Checked-Out	44000.00	10.00	0.00	0.00	Cash	13200.00	2025-10-06 23:33:18.829019+05:30
492	\N	64	21	2025-09-23	2025-09-26	Checked-Out	44000.00	10.00	0.00	0.00	Online	13200.00	2025-10-06 23:33:18.829019+05:30
496	\N	30	22	2025-07-10	2025-07-15	Checked-In	40000.00	10.00	0.00	0.00	Online	20000.00	2025-10-06 23:33:18.829019+05:30
498	\N	47	22	2025-07-20	2025-07-23	Checked-In	40000.00	10.00	0.00	0.00	Online	12000.00	2025-10-06 23:33:18.829019+05:30
499	\N	141	22	2025-07-23	2025-07-26	Checked-In	40000.00	10.00	0.00	0.00	BankTransfer	12000.00	2025-10-06 23:33:18.829019+05:30
503	\N	100	22	2025-08-07	2025-08-11	Checked-In	44000.00	10.00	0.00	0.00	Online	17600.00	2025-10-06 23:33:18.829019+05:30
504	\N	115	22	2025-08-12	2025-08-15	Checked-Out	44000.00	10.00	0.00	0.00	Online	13200.00	2025-10-06 23:33:18.829019+05:30
508	\N	143	22	2025-08-30	2025-09-01	Checked-Out	47520.00	10.00	0.00	0.00	Online	9504.00	2025-10-06 23:33:18.829019+05:30
509	\N	29	22	2025-09-01	2025-09-04	Checked-Out	44000.00	10.00	0.00	0.00	Card	13200.00	2025-10-06 23:33:18.829019+05:30
510	\N	16	22	2025-09-04	2025-09-05	Checked-Out	44000.00	10.00	0.00	0.00	Online	4400.00	2025-10-06 23:33:18.829019+05:30
512	\N	139	22	2025-09-12	2025-09-14	Checked-Out	47520.00	10.00	0.00	0.00	BankTransfer	9504.00	2025-10-06 23:33:18.829019+05:30
513	\N	19	22	2025-09-14	2025-09-19	Checked-In	44000.00	10.00	0.00	0.00	BankTransfer	22000.00	2025-10-06 23:33:18.829019+05:30
514	\N	12	22	2025-09-19	2025-09-21	Checked-Out	47520.00	10.00	0.00	0.00	Online	9504.00	2025-10-06 23:33:18.829019+05:30
516	\N	121	22	2025-09-26	2025-09-28	Checked-Out	47520.00	10.00	0.00	0.00	BankTransfer	9504.00	2025-10-06 23:33:18.829019+05:30
518	\N	57	23	2025-07-01	2025-07-03	Checked-Out	40000.00	10.00	0.00	0.00	Online	8000.00	2025-10-06 23:33:18.829019+05:30
520	\N	106	23	2025-07-05	2025-07-08	Checked-Out	43200.00	10.00	0.00	0.00	Cash	12960.00	2025-10-06 23:33:18.829019+05:30
523	\N	28	23	2025-07-17	2025-07-21	Checked-Out	40000.00	10.00	0.00	0.00	Cash	16000.00	2025-10-06 23:33:18.829019+05:30
524	\N	62	23	2025-07-22	2025-07-24	Checked-Out	40000.00	10.00	0.00	0.00	Cash	8000.00	2025-10-06 23:33:18.829019+05:30
526	\N	70	23	2025-07-26	2025-07-31	Checked-Out	43200.00	10.00	0.00	0.00	Card	21600.00	2025-10-06 23:33:18.829019+05:30
528	\N	100	23	2025-08-08	2025-08-11	Checked-Out	47520.00	10.00	0.00	0.00	BankTransfer	14256.00	2025-10-06 23:33:18.829019+05:30
529	\N	129	23	2025-08-12	2025-08-13	Checked-Out	44000.00	10.00	0.00	0.00	Cash	4400.00	2025-10-06 23:33:18.829019+05:30
530	\N	110	23	2025-08-15	2025-08-18	Checked-Out	47520.00	10.00	0.00	0.00	BankTransfer	14256.00	2025-10-06 23:33:18.829019+05:30
531	\N	33	23	2025-08-19	2025-08-21	Checked-Out	44000.00	10.00	0.00	0.00	Online	8800.00	2025-10-06 23:33:18.829019+05:30
533	\N	103	23	2025-08-28	2025-09-01	Checked-In	44000.00	10.00	0.00	0.00	BankTransfer	17600.00	2025-10-06 23:33:18.829019+05:30
534	\N	11	23	2025-09-02	2025-09-05	Checked-In	44000.00	10.00	0.00	0.00	Cash	13200.00	2025-10-06 23:33:18.829019+05:30
535	\N	35	23	2025-09-05	2025-09-08	Checked-Out	47520.00	10.00	0.00	0.00	Online	14256.00	2025-10-06 23:33:18.829019+05:30
538	\N	8	23	2025-09-16	2025-09-17	Checked-Out	44000.00	10.00	0.00	0.00	Cash	4400.00	2025-10-06 23:33:18.829019+05:30
540	\N	60	23	2025-09-24	2025-09-26	Checked-Out	44000.00	10.00	0.00	0.00	Cash	8800.00	2025-10-06 23:33:18.829019+05:30
543	\N	80	24	2025-07-01	2025-07-04	Checked-Out	24000.00	10.00	0.00	0.00	Cash	7200.00	2025-10-06 23:33:18.829019+05:30
544	\N	25	24	2025-07-05	2025-07-06	Checked-Out	25920.00	10.00	0.00	0.00	Online	2592.00	2025-10-06 23:33:18.829019+05:30
545	\N	74	24	2025-07-06	2025-07-07	Checked-Out	24000.00	10.00	0.00	0.00	Cash	2400.00	2025-10-06 23:33:18.829019+05:30
546	\N	96	24	2025-07-08	2025-07-12	Checked-Out	24000.00	10.00	0.00	0.00	Cash	9600.00	2025-10-06 23:33:18.829019+05:30
552	\N	116	24	2025-07-27	2025-08-01	Checked-Out	24000.00	10.00	0.00	0.00	Online	12000.00	2025-10-06 23:33:18.829019+05:30
555	\N	139	24	2025-08-10	2025-08-13	Checked-Out	26400.00	10.00	0.00	0.00	Online	7920.00	2025-10-06 23:33:18.829019+05:30
558	\N	148	24	2025-08-25	2025-08-26	Checked-In	26400.00	10.00	0.00	0.00	Cash	2640.00	2025-10-06 23:33:18.829019+05:30
562	\N	121	24	2025-09-06	2025-09-10	Checked-Out	28512.00	10.00	0.00	0.00	Online	11404.80	2025-10-06 23:33:18.829019+05:30
563	\N	120	24	2025-09-10	2025-09-14	Checked-Out	26400.00	10.00	0.00	0.00	Online	10560.00	2025-10-06 23:33:18.829019+05:30
567	\N	69	24	2025-09-28	2025-09-30	Checked-Out	26400.00	10.00	0.00	0.00	BankTransfer	5280.00	2025-10-06 23:33:18.829019+05:30
568	\N	90	25	2025-07-01	2025-07-06	Checked-In	24000.00	10.00	0.00	0.00	Online	12000.00	2025-10-06 23:33:18.829019+05:30
570	\N	96	25	2025-07-11	2025-07-13	Checked-Out	25920.00	10.00	0.00	0.00	Online	5184.00	2025-10-06 23:33:18.829019+05:30
502	\N	20	22	2025-08-02	2025-08-06	Checked-Out	47520.00	10.00	6958.18	0.00	Cash	19008.00	2025-10-06 23:33:18.829019+05:30
507	\N	20	22	2025-08-25	2025-08-29	Checked-In	44000.00	10.00	0.00	9915.51	Cash	17600.00	2025-10-06 23:33:18.829019+05:30
515	\N	116	22	2025-09-23	2025-09-25	Checked-Out	44000.00	10.00	6667.32	0.00	Online	8800.00	2025-10-06 23:33:18.829019+05:30
519	\N	146	23	2025-07-03	2025-07-04	Checked-Out	40000.00	10.00	4302.65	0.00	Cash	4000.00	2025-10-06 23:33:18.829019+05:30
511	\N	67	22	2025-09-06	2025-09-11	Cancelled	47520.00	10.00	0.00	0.00	Cash	23760.00	2025-10-06 23:33:18.829019+05:30
525	\N	117	23	2025-07-24	2025-07-26	Checked-Out	40000.00	10.00	7172.06	0.00	Card	8000.00	2025-10-06 23:33:18.829019+05:30
698	\N	28	30	2025-08-18	2025-08-21	Checked-Out	19800.00	10.00	0.00	0.00	Cash	5940.00	2025-10-06 23:33:18.829019+05:30
532	\N	55	23	2025-08-22	2025-08-26	Checked-Out	47520.00	10.00	4316.53	0.00	Cash	19008.00	2025-10-06 23:33:18.829019+05:30
539	\N	36	23	2025-09-18	2025-09-23	Checked-Out	44000.00	10.00	5814.76	0.00	Card	22000.00	2025-10-06 23:33:18.829019+05:30
521	\N	75	23	2025-07-09	2025-07-14	Cancelled	40000.00	10.00	0.00	0.00	BankTransfer	20000.00	2025-10-06 23:33:18.829019+05:30
493	\N	57	21	2025-09-28	2025-10-02	Checked-Out	44000.00	10.00	6423.66	0.00	Online	17600.00	2025-10-06 23:33:18.829019+05:30
537	\N	73	23	2025-09-10	2025-09-15	Checked-Out	44000.00	10.00	2223.52	0.00	Cash	22000.00	2025-10-06 23:33:18.829019+05:30
542	\N	20	23	2025-09-29	2025-10-04	Checked-In	44000.00	10.00	2646.73	0.00	Cash	22000.00	2025-10-06 23:33:18.829019+05:30
559	\N	10	24	2025-08-27	2025-08-29	Cancelled	26400.00	10.00	0.00	0.00	Cash	5280.00	2025-10-06 23:33:18.829019+05:30
556	\N	35	24	2025-08-14	2025-08-17	Checked-In	26400.00	10.00	4074.32	0.00	Cash	7920.00	2025-10-06 23:33:18.829019+05:30
566	\N	65	24	2025-09-24	2025-09-26	Checked-In	26400.00	10.00	2866.17	0.00	Online	5280.00	2025-10-06 23:33:18.829019+05:30
571	\N	40	25	2025-07-15	2025-07-17	Checked-Out	24000.00	10.00	2613.51	0.00	Cash	4800.00	2025-10-06 23:33:18.829019+05:30
491	\N	138	21	2025-09-21	2025-09-23	Checked-Out	44000.00	10.00	5404.78	0.00	Online	8800.00	2025-10-06 23:33:18.829019+05:30
494	\N	105	22	2025-07-01	2025-07-03	Checked-Out	40000.00	10.00	4913.43	0.00	Card	8000.00	2025-10-06 23:33:18.829019+05:30
500	\N	38	22	2025-07-27	2025-07-28	Checked-Out	40000.00	10.00	4913.43	0.00	BankTransfer	4000.00	2025-10-06 23:33:18.829019+05:30
536	\N	88	23	2025-09-08	2025-09-10	Checked-In	44000.00	10.00	5404.78	0.00	Online	8800.00	2025-10-06 23:33:18.829019+05:30
554	\N	27	24	2025-08-07	2025-08-08	Checked-Out	26400.00	10.00	3242.87	0.00	Card	2640.00	2025-10-06 23:33:18.829019+05:30
522	\N	92	23	2025-07-15	2025-07-17	Checked-In	40000.00	10.00	4913.43	0.00	Cash	8000.00	2025-10-06 23:33:18.829019+05:30
541	\N	72	23	2025-09-27	2025-09-29	Checked-In	47520.00	10.00	5837.16	0.00	Card	9504.00	2025-10-06 23:33:18.829019+05:30
505	\N	24	22	2025-08-16	2025-08-18	Cancelled	47520.00	10.00	4232.48	0.00	Online	9504.00	2025-10-06 23:33:18.829019+05:30
569	\N	29	25	2025-07-07	2025-07-10	Checked-Out	24000.00	10.00	0.00	7055.85	Cash	7200.00	2025-10-06 23:33:18.829019+05:30
497	\N	32	22	2025-07-15	2025-07-18	Checked-In	40000.00	10.00	4114.57	4555.00	Online	12000.00	2025-10-06 23:33:18.829019+05:30
557	\N	95	24	2025-08-19	2025-08-23	Checked-Out	26400.00	10.00	2722.90	4818.01	Cash	10560.00	2025-10-06 23:33:18.829019+05:30
573	\N	55	25	2025-07-22	2025-07-24	Checked-In	24000.00	10.00	0.00	0.00	Online	4800.00	2025-10-06 23:33:18.829019+05:30
576	\N	129	25	2025-08-04	2025-08-08	Checked-Out	26400.00	10.00	0.00	0.00	Cash	10560.00	2025-10-06 23:33:18.829019+05:30
577	\N	149	25	2025-08-08	2025-08-10	Checked-Out	28512.00	10.00	0.00	0.00	Cash	5702.40	2025-10-06 23:33:18.829019+05:30
580	\N	47	25	2025-08-19	2025-08-22	Checked-Out	26400.00	10.00	0.00	0.00	Cash	7920.00	2025-10-06 23:33:18.829019+05:30
582	\N	70	25	2025-08-30	2025-09-01	Checked-Out	28512.00	10.00	0.00	0.00	Cash	5702.40	2025-10-06 23:33:18.829019+05:30
583	\N	24	25	2025-09-02	2025-09-04	Checked-Out	26400.00	10.00	0.00	0.00	BankTransfer	5280.00	2025-10-06 23:33:18.829019+05:30
589	\N	108	25	2025-09-22	2025-09-26	Checked-Out	26400.00	10.00	0.00	0.00	Card	10560.00	2025-10-06 23:33:18.829019+05:30
590	\N	18	25	2025-09-26	2025-09-28	Checked-Out	28512.00	10.00	0.00	0.00	Cash	5702.40	2025-10-06 23:33:18.829019+05:30
594	\N	79	26	2025-07-11	2025-07-15	Checked-Out	25920.00	10.00	0.00	0.00	Card	10368.00	2025-10-06 23:33:18.829019+05:30
596	\N	17	26	2025-07-23	2025-07-26	Checked-Out	24000.00	10.00	0.00	0.00	Online	7200.00	2025-10-06 23:33:18.829019+05:30
597	\N	145	26	2025-07-28	2025-07-31	Checked-Out	24000.00	10.00	0.00	0.00	Online	7200.00	2025-10-06 23:33:18.829019+05:30
599	\N	119	26	2025-08-06	2025-08-08	Checked-Out	26400.00	10.00	0.00	0.00	Cash	5280.00	2025-10-06 23:33:18.829019+05:30
600	\N	44	26	2025-08-09	2025-08-13	Checked-Out	28512.00	10.00	0.00	0.00	Online	11404.80	2025-10-06 23:33:18.829019+05:30
601	\N	120	26	2025-08-14	2025-08-18	Checked-In	26400.00	10.00	0.00	0.00	Online	10560.00	2025-10-06 23:33:18.829019+05:30
602	\N	31	26	2025-08-19	2025-08-24	Checked-Out	26400.00	10.00	0.00	0.00	Online	13200.00	2025-10-06 23:33:18.829019+05:30
608	\N	94	26	2025-09-13	2025-09-15	Checked-Out	28512.00	10.00	0.00	0.00	Card	5702.40	2025-10-06 23:33:18.829019+05:30
611	\N	10	26	2025-09-23	2025-09-24	Checked-Out	26400.00	10.00	0.00	0.00	Cash	2640.00	2025-10-06 23:33:18.829019+05:30
612	\N	71	26	2025-09-26	2025-09-29	Checked-In	28512.00	10.00	0.00	0.00	Cash	8553.60	2025-10-06 23:33:18.829019+05:30
613	\N	137	26	2025-09-30	2025-10-02	Checked-Out	26400.00	10.00	0.00	0.00	Online	5280.00	2025-10-06 23:33:18.829019+05:30
614	\N	105	27	2025-07-01	2025-07-06	Checked-Out	24000.00	10.00	0.00	0.00	BankTransfer	12000.00	2025-10-06 23:33:18.829019+05:30
617	\N	53	27	2025-07-18	2025-07-21	Checked-Out	25920.00	10.00	0.00	0.00	BankTransfer	7776.00	2025-10-06 23:33:18.829019+05:30
618	\N	149	27	2025-07-21	2025-07-23	Checked-Out	24000.00	10.00	0.00	0.00	Cash	4800.00	2025-10-06 23:33:18.829019+05:30
621	\N	4	27	2025-07-30	2025-08-02	Checked-Out	24000.00	10.00	0.00	0.00	BankTransfer	7200.00	2025-10-06 23:33:18.829019+05:30
626	\N	57	27	2025-08-21	2025-08-22	Checked-Out	26400.00	10.00	0.00	0.00	Cash	2640.00	2025-10-06 23:33:18.829019+05:30
627	\N	6	27	2025-08-22	2025-08-25	Checked-Out	28512.00	10.00	0.00	0.00	Cash	8553.60	2025-10-06 23:33:18.829019+05:30
628	\N	94	27	2025-08-26	2025-08-28	Checked-Out	26400.00	10.00	0.00	0.00	Online	5280.00	2025-10-06 23:33:18.829019+05:30
630	\N	137	27	2025-09-04	2025-09-08	Checked-Out	26400.00	10.00	0.00	0.00	BankTransfer	10560.00	2025-10-06 23:33:18.829019+05:30
631	\N	53	27	2025-09-09	2025-09-11	Checked-In	26400.00	10.00	0.00	0.00	Online	5280.00	2025-10-06 23:33:18.829019+05:30
632	\N	102	27	2025-09-11	2025-09-15	Checked-Out	26400.00	10.00	0.00	0.00	Online	10560.00	2025-10-06 23:33:18.829019+05:30
633	\N	24	27	2025-09-16	2025-09-19	Checked-In	26400.00	10.00	0.00	0.00	Cash	7920.00	2025-10-06 23:33:18.829019+05:30
636	\N	106	27	2025-09-30	2025-10-05	Checked-Out	26400.00	10.00	0.00	0.00	Online	13200.00	2025-10-06 23:33:18.829019+05:30
637	\N	49	28	2025-07-01	2025-07-04	Checked-Out	24000.00	10.00	0.00	0.00	BankTransfer	7200.00	2025-10-06 23:33:18.829019+05:30
638	\N	144	28	2025-07-04	2025-07-07	Checked-Out	25920.00	10.00	0.00	0.00	Online	7776.00	2025-10-06 23:33:18.829019+05:30
639	\N	75	28	2025-07-08	2025-07-12	Checked-Out	24000.00	10.00	0.00	0.00	Online	9600.00	2025-10-06 23:33:18.829019+05:30
640	\N	57	28	2025-07-13	2025-07-17	Checked-Out	24000.00	10.00	0.00	0.00	Card	9600.00	2025-10-06 23:33:18.829019+05:30
641	\N	143	28	2025-07-17	2025-07-21	Checked-Out	24000.00	10.00	0.00	0.00	Cash	9600.00	2025-10-06 23:33:18.829019+05:30
643	\N	1	28	2025-07-28	2025-07-30	Checked-Out	24000.00	10.00	0.00	0.00	Card	4800.00	2025-10-06 23:33:18.829019+05:30
645	\N	64	28	2025-08-03	2025-08-05	Checked-Out	26400.00	10.00	0.00	0.00	Cash	5280.00	2025-10-06 23:33:18.829019+05:30
646	\N	135	28	2025-08-06	2025-08-07	Checked-Out	26400.00	10.00	0.00	0.00	Online	2640.00	2025-10-06 23:33:18.829019+05:30
647	\N	121	28	2025-08-08	2025-08-09	Checked-In	28512.00	10.00	0.00	0.00	Cash	2851.20	2025-10-06 23:33:18.829019+05:30
648	\N	69	28	2025-08-10	2025-08-12	Checked-Out	26400.00	10.00	0.00	0.00	Online	5280.00	2025-10-06 23:33:18.829019+05:30
649	\N	46	28	2025-08-13	2025-08-17	Checked-In	26400.00	10.00	0.00	0.00	Cash	10560.00	2025-10-06 23:33:18.829019+05:30
651	\N	73	28	2025-08-20	2025-08-22	Checked-Out	26400.00	10.00	0.00	0.00	BankTransfer	5280.00	2025-10-06 23:33:18.829019+05:30
572	\N	29	25	2025-07-18	2025-07-20	Checked-Out	25920.00	10.00	2042.84	0.00	BankTransfer	5184.00	2025-10-06 23:33:18.829019+05:30
1440	\N	1	2	2025-11-10	2025-11-12	Booked	20000.00	10.00	0.00	0.00	\N	5000.00	2025-10-07 11:32:12.262156+05:30
790	\N	99	34	2025-08-17	2025-08-20	Checked-Out	19800.00	10.00	0.00	0.00	Cash	5940.00	2025-10-06 23:33:18.829019+05:30
584	\N	1	25	2025-09-05	2025-09-09	Checked-Out	28512.00	10.00	4633.92	0.00	Online	11404.80	2025-10-06 23:33:18.829019+05:30
588	\N	51	25	2025-09-20	2025-09-22	Cancelled	28512.00	10.00	0.00	0.00	Cash	5702.40	2025-10-06 23:33:18.829019+05:30
591	\N	55	25	2025-09-29	2025-10-04	Checked-In	26400.00	10.00	3021.09	0.00	Card	13200.00	2025-10-06 23:33:18.829019+05:30
652	\N	55	28	2025-08-23	2025-08-25	Checked-Out	28512.00	10.00	4613.61	0.00	Card	5702.40	2025-10-06 23:33:18.829019+05:30
579	\N	25	25	2025-08-14	2025-08-17	Checked-Out	26400.00	10.00	5238.78	0.00	BankTransfer	7920.00	2025-10-06 23:33:18.829019+05:30
581	\N	79	25	2025-08-24	2025-08-29	Checked-In	26400.00	10.00	4887.95	0.00	Card	13200.00	2025-10-06 23:33:18.829019+05:30
586	\N	59	25	2025-09-16	2025-09-17	Checked-Out	26400.00	10.00	4843.63	0.00	BankTransfer	2640.00	2025-10-06 23:33:18.829019+05:30
624	\N	105	27	2025-08-14	2025-08-17	Cancelled	26400.00	10.00	3123.24	0.00	Cash	7920.00	2025-10-06 23:33:18.829019+05:30
603	\N	71	26	2025-08-25	2025-08-29	Checked-Out	26400.00	10.00	5026.53	0.00	Card	10560.00	2025-10-06 23:33:18.829019+05:30
609	\N	122	26	2025-09-16	2025-09-19	Checked-In	26400.00	10.00	2931.04	0.00	BankTransfer	7920.00	2025-10-06 23:33:18.829019+05:30
607	\N	7	26	2025-09-09	2025-09-12	Checked-Out	26400.00	10.00	3242.87	0.00	Cash	7920.00	2025-10-06 23:33:18.829019+05:30
629	\N	88	27	2025-08-29	2025-09-03	Checked-Out	28512.00	10.00	3502.30	0.00	Card	14256.00	2025-10-06 23:33:18.829019+05:30
634	\N	58	27	2025-09-20	2025-09-24	Checked-Out	28512.00	10.00	3502.30	0.00	Card	11404.80	2025-10-06 23:33:18.829019+05:30
585	\N	100	25	2025-09-10	2025-09-15	Checked-Out	26400.00	10.00	3242.87	0.00	BankTransfer	13200.00	2025-10-06 23:33:18.829019+05:30
592	\N	106	26	2025-07-01	2025-07-04	Checked-Out	24000.00	10.00	2948.06	0.00	Cash	7200.00	2025-10-06 23:33:18.829019+05:30
578	\N	13	25	2025-08-11	2025-08-13	Checked-Out	26400.00	10.00	0.00	7707.81	Card	5280.00	2025-10-06 23:33:18.829019+05:30
610	\N	90	26	2025-09-20	2025-09-21	Checked-Out	28512.00	10.00	0.00	6599.82	Cash	2851.20	2025-10-06 23:33:18.829019+05:30
616	\N	40	27	2025-07-12	2025-07-17	Checked-Out	25920.00	10.00	0.00	2697.51	Online	12960.00	2025-10-06 23:33:18.829019+05:30
642	\N	39	28	2025-07-23	2025-07-26	Checked-Out	24000.00	10.00	0.00	2950.24	Cash	7200.00	2025-10-06 23:33:18.829019+05:30
650	\N	104	28	2025-08-17	2025-08-20	Checked-In	26400.00	10.00	0.00	5873.29	Online	7920.00	2025-10-06 23:33:18.829019+05:30
575	\N	119	25	2025-07-30	2025-08-02	Checked-Out	24000.00	10.00	3786.35	3228.74	Card	7200.00	2025-10-06 23:33:18.829019+05:30
598	\N	14	26	2025-08-01	2025-08-05	Checked-In	28512.00	10.00	3502.30	6512.34	Card	11404.80	2025-10-06 23:33:18.829019+05:30
653	\N	17	28	2025-08-26	2025-08-29	Checked-Out	26400.00	10.00	0.00	0.00	Cash	7920.00	2025-10-06 23:33:18.829019+05:30
656	\N	5	28	2025-09-06	2025-09-09	Checked-Out	28512.00	10.00	0.00	0.00	Cash	8553.60	2025-10-06 23:33:18.829019+05:30
657	\N	3	28	2025-09-10	2025-09-13	Checked-Out	26400.00	10.00	0.00	0.00	BankTransfer	7920.00	2025-10-06 23:33:18.829019+05:30
659	\N	136	28	2025-09-21	2025-09-24	Checked-In	26400.00	10.00	0.00	0.00	Cash	7920.00	2025-10-06 23:33:18.829019+05:30
660	\N	33	28	2025-09-25	2025-09-28	Checked-Out	26400.00	10.00	0.00	0.00	Online	7920.00	2025-10-06 23:33:18.829019+05:30
661	\N	130	28	2025-09-30	2025-10-05	Checked-In	26400.00	10.00	0.00	0.00	Cash	13200.00	2025-10-06 23:33:18.829019+05:30
663	\N	4	29	2025-07-03	2025-07-05	Checked-Out	18000.00	10.00	0.00	0.00	Card	3600.00	2025-10-06 23:33:18.829019+05:30
664	\N	131	29	2025-07-06	2025-07-09	Checked-In	18000.00	10.00	0.00	0.00	Cash	5400.00	2025-10-06 23:33:18.829019+05:30
665	\N	133	29	2025-07-11	2025-07-14	Checked-Out	19440.00	10.00	0.00	0.00	Online	5832.00	2025-10-06 23:33:18.829019+05:30
668	\N	66	29	2025-07-24	2025-07-26	Checked-Out	18000.00	10.00	0.00	0.00	Cash	3600.00	2025-10-06 23:33:18.829019+05:30
669	\N	35	29	2025-07-27	2025-07-28	Checked-Out	18000.00	10.00	0.00	0.00	Cash	1800.00	2025-10-06 23:33:18.829019+05:30
670	\N	117	29	2025-07-29	2025-07-30	Checked-Out	18000.00	10.00	0.00	0.00	Card	1800.00	2025-10-06 23:33:18.829019+05:30
671	\N	82	29	2025-08-01	2025-08-04	Checked-Out	21384.00	10.00	0.00	0.00	Online	6415.20	2025-10-06 23:33:18.829019+05:30
672	\N	56	29	2025-08-04	2025-08-05	Checked-In	19800.00	10.00	0.00	0.00	Cash	1980.00	2025-10-06 23:33:18.829019+05:30
676	\N	27	29	2025-08-21	2025-08-24	Checked-Out	19800.00	10.00	0.00	0.00	Card	5940.00	2025-10-06 23:33:18.829019+05:30
677	\N	128	29	2025-08-25	2025-08-30	Checked-Out	19800.00	10.00	0.00	0.00	Card	9900.00	2025-10-06 23:33:18.829019+05:30
678	\N	62	29	2025-08-31	2025-09-03	Checked-Out	19800.00	10.00	0.00	0.00	BankTransfer	5940.00	2025-10-06 23:33:18.829019+05:30
680	\N	96	29	2025-09-06	2025-09-10	Checked-Out	21384.00	10.00	0.00	0.00	Online	8553.60	2025-10-06 23:33:18.829019+05:30
681	\N	35	29	2025-09-11	2025-09-14	Checked-In	19800.00	10.00	0.00	0.00	Online	5940.00	2025-10-06 23:33:18.829019+05:30
686	\N	4	30	2025-07-01	2025-07-03	Checked-Out	18000.00	10.00	0.00	0.00	Cash	3600.00	2025-10-06 23:33:18.829019+05:30
689	\N	135	30	2025-07-10	2025-07-15	Checked-In	18000.00	10.00	0.00	0.00	Cash	9000.00	2025-10-06 23:33:18.829019+05:30
690	\N	37	30	2025-07-15	2025-07-16	Checked-Out	18000.00	10.00	0.00	0.00	Online	1800.00	2025-10-06 23:33:18.829019+05:30
694	\N	128	30	2025-07-29	2025-08-03	Checked-Out	18000.00	10.00	0.00	0.00	Cash	9000.00	2025-10-06 23:33:18.829019+05:30
695	\N	110	30	2025-08-04	2025-08-09	Checked-Out	19800.00	10.00	0.00	0.00	Online	9900.00	2025-10-06 23:33:18.829019+05:30
696	\N	88	30	2025-08-11	2025-08-15	Checked-In	19800.00	10.00	0.00	0.00	Card	7920.00	2025-10-06 23:33:18.829019+05:30
697	\N	122	30	2025-08-15	2025-08-18	Checked-Out	21384.00	10.00	0.00	0.00	Card	6415.20	2025-10-06 23:33:18.829019+05:30
699	\N	112	30	2025-08-22	2025-08-24	Checked-Out	21384.00	10.00	0.00	0.00	Cash	4276.80	2025-10-06 23:33:18.829019+05:30
700	\N	34	30	2025-08-24	2025-08-29	Checked-Out	19800.00	10.00	0.00	0.00	BankTransfer	9900.00	2025-10-06 23:33:18.829019+05:30
701	\N	92	30	2025-08-30	2025-09-04	Checked-In	21384.00	10.00	0.00	0.00	Online	10692.00	2025-10-06 23:33:18.829019+05:30
702	\N	85	30	2025-09-04	2025-09-06	Checked-In	19800.00	10.00	0.00	0.00	Card	3960.00	2025-10-06 23:33:18.829019+05:30
703	\N	6	30	2025-09-08	2025-09-11	Checked-Out	19800.00	10.00	0.00	0.00	Online	5940.00	2025-10-06 23:33:18.829019+05:30
704	\N	92	30	2025-09-12	2025-09-16	Checked-Out	21384.00	10.00	0.00	0.00	Card	8553.60	2025-10-06 23:33:18.829019+05:30
705	\N	60	30	2025-09-17	2025-09-20	Checked-In	19800.00	10.00	0.00	0.00	Card	5940.00	2025-10-06 23:33:18.829019+05:30
706	\N	92	30	2025-09-21	2025-09-26	Checked-Out	19800.00	10.00	0.00	0.00	Online	9900.00	2025-10-06 23:33:18.829019+05:30
707	\N	113	30	2025-09-27	2025-10-02	Checked-Out	21384.00	10.00	0.00	0.00	Cash	10692.00	2025-10-06 23:33:18.829019+05:30
708	\N	32	31	2025-07-01	2025-07-03	Checked-In	18000.00	10.00	0.00	0.00	Online	3600.00	2025-10-06 23:33:18.829019+05:30
709	\N	137	31	2025-07-04	2025-07-06	Checked-In	19440.00	10.00	0.00	0.00	Card	3888.00	2025-10-06 23:33:18.829019+05:30
710	\N	21	31	2025-07-08	2025-07-13	Checked-Out	18000.00	10.00	0.00	0.00	Online	9000.00	2025-10-06 23:33:18.829019+05:30
711	\N	127	31	2025-07-14	2025-07-19	Checked-Out	18000.00	10.00	0.00	0.00	Online	9000.00	2025-10-06 23:33:18.829019+05:30
713	\N	5	31	2025-07-27	2025-07-31	Checked-Out	18000.00	10.00	0.00	0.00	BankTransfer	7200.00	2025-10-06 23:33:18.829019+05:30
714	\N	134	31	2025-07-31	2025-08-04	Checked-Out	18000.00	10.00	0.00	0.00	Cash	7200.00	2025-10-06 23:33:18.829019+05:30
715	\N	1	31	2025-08-05	2025-08-08	Checked-In	19800.00	10.00	0.00	0.00	Online	5940.00	2025-10-06 23:33:18.829019+05:30
716	\N	41	31	2025-08-08	2025-08-09	Checked-Out	21384.00	10.00	0.00	0.00	Online	2138.40	2025-10-06 23:33:18.829019+05:30
1441	\N	1	1	2025-11-12	2025-11-14	Checked-In	20000.00	10.00	0.00	0.00	\N	4000.00	2025-10-07 11:33:02.276951+05:30
720	\N	51	31	2025-08-26	2025-08-30	Checked-Out	19800.00	10.00	0.00	0.00	Online	7920.00	2025-10-06 23:33:18.829019+05:30
721	\N	135	31	2025-08-31	2025-09-04	Checked-In	19800.00	10.00	0.00	0.00	Online	7920.00	2025-10-06 23:33:18.829019+05:30
723	\N	15	31	2025-09-10	2025-09-14	Checked-Out	19800.00	10.00	0.00	0.00	BankTransfer	7920.00	2025-10-06 23:33:18.829019+05:30
724	\N	61	31	2025-09-15	2025-09-18	Checked-Out	19800.00	10.00	0.00	0.00	Online	5940.00	2025-10-06 23:33:18.829019+05:30
728	\N	33	32	2025-07-03	2025-07-07	Checked-Out	18000.00	10.00	0.00	0.00	Cash	7200.00	2025-10-06 23:33:18.829019+05:30
731	\N	126	32	2025-07-14	2025-07-17	Checked-Out	18000.00	10.00	0.00	0.00	BankTransfer	5400.00	2025-10-06 23:33:18.829019+05:30
655	\N	97	28	2025-09-03	2025-09-05	Checked-Out	26400.00	10.00	2339.83	0.00	BankTransfer	5280.00	2025-10-06 23:33:18.829019+05:30
662	\N	120	29	2025-07-01	2025-07-03	Checked-In	18000.00	10.00	0.00	3285.05	BankTransfer	3600.00	2025-10-06 23:33:18.829019+05:30
692	\N	43	30	2025-07-22	2025-07-26	Checked-Out	18000.00	10.00	2476.42	0.00	Cash	7200.00	2025-10-06 23:33:18.829019+05:30
727	\N	77	32	2025-07-01	2025-07-03	Checked-Out	18000.00	10.00	1257.41	0.00	Cash	3600.00	2025-10-06 23:33:18.829019+05:30
729	\N	57	32	2025-07-08	2025-07-13	Checked-In	18000.00	10.00	1240.56	0.00	Online	9000.00	2025-10-06 23:33:18.829019+05:30
667	\N	37	29	2025-07-20	2025-07-24	Checked-Out	18000.00	10.00	1526.95	0.00	Card	7200.00	2025-10-06 23:33:18.829019+05:30
673	\N	6	29	2025-08-07	2025-08-11	Checked-Out	19800.00	10.00	1684.37	0.00	Card	7920.00	2025-10-06 23:33:18.829019+05:30
674	\N	69	29	2025-08-13	2025-08-15	Checked-In	19800.00	10.00	1044.10	0.00	BankTransfer	3960.00	2025-10-06 23:33:18.829019+05:30
682	\N	22	29	2025-09-16	2025-09-21	Checked-Out	19800.00	10.00	3328.61	0.00	Cash	9900.00	2025-10-06 23:33:18.829019+05:30
683	\N	110	29	2025-09-22	2025-09-25	Checked-Out	19800.00	10.00	2414.23	0.00	Cash	5940.00	2025-10-06 23:33:18.829019+05:30
691	\N	7	30	2025-07-17	2025-07-21	Checked-Out	18000.00	10.00	0.00	4780.25	Online	7200.00	2025-10-06 23:33:18.829019+05:30
712	\N	105	31	2025-07-21	2025-07-25	Cancelled	18000.00	10.00	0.00	0.00	Cash	7200.00	2025-10-06 23:33:18.829019+05:30
684	\N	137	29	2025-09-26	2025-09-28	Checked-Out	21384.00	10.00	2626.72	0.00	Online	4276.80	2025-10-06 23:33:18.829019+05:30
719	\N	42	31	2025-08-21	2025-08-25	Checked-Out	19800.00	10.00	2432.15	0.00	Card	7920.00	2025-10-06 23:33:18.829019+05:30
718	\N	130	31	2025-08-16	2025-08-19	Checked-In	21384.00	10.00	2626.72	0.00	BankTransfer	6415.20	2025-10-06 23:33:18.829019+05:30
654	\N	78	28	2025-08-30	2025-09-03	Cancelled	28512.00	10.00	3502.30	0.00	Online	11404.80	2025-10-06 23:33:18.829019+05:30
688	\N	145	30	2025-07-05	2025-07-09	Cancelled	19440.00	10.00	3181.80	0.00	Cash	7776.00	2025-10-06 23:33:18.829019+05:30
722	\N	3	31	2025-09-05	2025-09-09	Checked-Out	21384.00	10.00	0.00	4114.39	Card	8553.60	2025-10-06 23:33:18.829019+05:30
658	\N	141	28	2025-09-14	2025-09-19	Checked-Out	26400.00	10.00	4454.77	2970.90	BankTransfer	13200.00	2025-10-06 23:33:18.829019+05:30
693	\N	36	30	2025-07-27	2025-07-29	Checked-Out	18000.00	10.00	1940.53	5191.06	Cash	3600.00	2025-10-06 23:33:18.829019+05:30
737	\N	123	32	2025-08-07	2025-08-08	Checked-Out	19800.00	10.00	0.00	0.00	Cash	1980.00	2025-10-06 23:33:18.829019+05:30
738	\N	61	32	2025-08-09	2025-08-10	Checked-In	21384.00	10.00	0.00	0.00	Online	2138.40	2025-10-06 23:33:18.829019+05:30
739	\N	138	32	2025-08-10	2025-08-14	Checked-Out	19800.00	10.00	0.00	0.00	Online	7920.00	2025-10-06 23:33:18.829019+05:30
743	\N	128	32	2025-08-28	2025-08-29	Checked-In	19800.00	10.00	0.00	0.00	Online	1980.00	2025-10-06 23:33:18.829019+05:30
744	\N	60	32	2025-08-31	2025-09-04	Checked-Out	19800.00	10.00	0.00	0.00	BankTransfer	7920.00	2025-10-06 23:33:18.829019+05:30
745	\N	6	32	2025-09-04	2025-09-07	Checked-Out	19800.00	10.00	0.00	0.00	Card	5940.00	2025-10-06 23:33:18.829019+05:30
748	\N	75	32	2025-09-16	2025-09-20	Checked-Out	19800.00	10.00	0.00	0.00	BankTransfer	7920.00	2025-10-06 23:33:18.829019+05:30
750	\N	89	32	2025-09-25	2025-09-30	Checked-Out	19800.00	10.00	0.00	0.00	Online	9900.00	2025-10-06 23:33:18.829019+05:30
753	\N	40	33	2025-07-06	2025-07-11	Checked-Out	18000.00	10.00	0.00	0.00	Card	9000.00	2025-10-06 23:33:18.829019+05:30
755	\N	45	33	2025-07-18	2025-07-22	Checked-Out	19440.00	10.00	0.00	0.00	Online	7776.00	2025-10-06 23:33:18.829019+05:30
756	\N	110	33	2025-07-24	2025-07-29	Checked-Out	18000.00	10.00	0.00	0.00	BankTransfer	9000.00	2025-10-06 23:33:18.829019+05:30
757	\N	137	33	2025-07-30	2025-08-03	Checked-Out	18000.00	10.00	0.00	0.00	Cash	7200.00	2025-10-06 23:33:18.829019+05:30
759	\N	38	33	2025-08-08	2025-08-13	Checked-Out	21384.00	10.00	0.00	0.00	Online	10692.00	2025-10-06 23:33:18.829019+05:30
760	\N	105	33	2025-08-14	2025-08-17	Checked-In	19800.00	10.00	0.00	0.00	Cash	5940.00	2025-10-06 23:33:18.829019+05:30
761	\N	24	33	2025-08-19	2025-08-23	Checked-In	19800.00	10.00	0.00	0.00	BankTransfer	7920.00	2025-10-06 23:33:18.829019+05:30
762	\N	124	33	2025-08-25	2025-08-28	Checked-Out	19800.00	10.00	0.00	0.00	Cash	5940.00	2025-10-06 23:33:18.829019+05:30
769	\N	20	33	2025-09-17	2025-09-20	Checked-In	19800.00	10.00	0.00	0.00	Online	5940.00	2025-10-06 23:33:18.829019+05:30
771	\N	122	33	2025-09-27	2025-09-29	Checked-Out	21384.00	10.00	0.00	0.00	Cash	4276.80	2025-10-06 23:33:18.829019+05:30
773	\N	129	34	2025-07-01	2025-07-04	Checked-In	18000.00	10.00	0.00	0.00	Online	5400.00	2025-10-06 23:33:18.829019+05:30
774	\N	21	34	2025-07-04	2025-07-05	Checked-Out	19440.00	10.00	0.00	0.00	Cash	1944.00	2025-10-06 23:33:18.829019+05:30
775	\N	13	34	2025-07-06	2025-07-09	Checked-In	18000.00	10.00	0.00	0.00	Cash	5400.00	2025-10-06 23:33:18.829019+05:30
778	\N	126	34	2025-07-13	2025-07-14	Checked-Out	18000.00	10.00	0.00	0.00	Online	1800.00	2025-10-06 23:33:18.829019+05:30
780	\N	136	34	2025-07-16	2025-07-18	Checked-Out	18000.00	10.00	0.00	0.00	Online	3600.00	2025-10-06 23:33:18.829019+05:30
781	\N	68	34	2025-07-18	2025-07-22	Checked-Out	19440.00	10.00	0.00	0.00	Card	7776.00	2025-10-06 23:33:18.829019+05:30
782	\N	2	34	2025-07-22	2025-07-26	Checked-In	18000.00	10.00	0.00	0.00	BankTransfer	7200.00	2025-10-06 23:33:18.829019+05:30
784	\N	15	34	2025-08-02	2025-08-04	Checked-Out	21384.00	10.00	0.00	0.00	Cash	4276.80	2025-10-06 23:33:18.829019+05:30
786	\N	101	34	2025-08-06	2025-08-09	Checked-In	19800.00	10.00	0.00	0.00	Cash	5940.00	2025-10-06 23:33:18.829019+05:30
787	\N	104	34	2025-08-09	2025-08-10	Checked-Out	21384.00	10.00	0.00	0.00	Card	2138.40	2025-10-06 23:33:18.829019+05:30
789	\N	60	34	2025-08-15	2025-08-17	Checked-In	21384.00	10.00	0.00	0.00	Card	4276.80	2025-10-06 23:33:18.829019+05:30
792	\N	90	34	2025-08-24	2025-08-29	Checked-In	19800.00	10.00	0.00	0.00	BankTransfer	9900.00	2025-10-06 23:33:18.829019+05:30
793	\N	46	34	2025-08-31	2025-09-05	Checked-Out	19800.00	10.00	0.00	0.00	Online	9900.00	2025-10-06 23:33:18.829019+05:30
794	\N	15	34	2025-09-06	2025-09-09	Checked-Out	21384.00	10.00	0.00	0.00	Online	6415.20	2025-10-06 23:33:18.829019+05:30
795	\N	29	34	2025-09-10	2025-09-11	Checked-Out	19800.00	10.00	0.00	0.00	Online	1980.00	2025-10-06 23:33:18.829019+05:30
797	\N	13	34	2025-09-16	2025-09-21	Checked-Out	19800.00	10.00	0.00	0.00	Cash	9900.00	2025-10-06 23:33:18.829019+05:30
798	\N	72	34	2025-09-22	2025-09-25	Checked-Out	19800.00	10.00	0.00	0.00	Cash	5940.00	2025-10-06 23:33:18.829019+05:30
800	\N	41	34	2025-09-29	2025-10-03	Checked-Out	19800.00	10.00	0.00	0.00	Online	7920.00	2025-10-06 23:33:18.829019+05:30
801	\N	30	35	2025-07-01	2025-07-04	Checked-Out	18000.00	10.00	0.00	0.00	Card	5400.00	2025-10-06 23:33:18.829019+05:30
803	\N	131	35	2025-07-09	2025-07-11	Checked-Out	18000.00	10.00	0.00	0.00	Online	3600.00	2025-10-06 23:33:18.829019+05:30
804	\N	131	35	2025-07-11	2025-07-14	Checked-Out	19440.00	10.00	0.00	0.00	BankTransfer	5832.00	2025-10-06 23:33:18.829019+05:30
807	\N	92	35	2025-07-24	2025-07-26	Checked-Out	18000.00	10.00	0.00	0.00	Cash	3600.00	2025-10-06 23:33:18.829019+05:30
808	\N	132	35	2025-07-27	2025-07-30	Checked-Out	18000.00	10.00	0.00	0.00	BankTransfer	5400.00	2025-10-06 23:33:18.829019+05:30
809	\N	29	35	2025-07-31	2025-08-02	Checked-Out	18000.00	10.00	0.00	0.00	Cash	3600.00	2025-10-06 23:33:18.829019+05:30
957	\N	150	41	2025-08-17	2025-08-19	Checked-Out	44000.00	10.00	0.00	0.00	BankTransfer	8800.00	2025-10-06 23:33:18.829019+05:30
961	\N	64	41	2025-08-29	2025-09-03	Checked-Out	47520.00	10.00	0.00	0.00	Cash	23760.00	2025-10-06 23:33:18.829019+05:30
962	\N	100	41	2025-09-04	2025-09-06	Checked-In	44000.00	10.00	0.00	0.00	Cash	8800.00	2025-10-06 23:33:18.829019+05:30
963	\N	6	41	2025-09-06	2025-09-10	Checked-Out	47520.00	10.00	0.00	0.00	Cash	19008.00	2025-10-06 23:33:18.829019+05:30
965	\N	106	41	2025-09-16	2025-09-21	Checked-Out	44000.00	10.00	0.00	0.00	Cash	22000.00	2025-10-06 23:33:18.829019+05:30
810	\N	25	35	2025-08-03	2025-08-06	Checked-Out	19800.00	10.00	0.00	0.00	Online	5940.00	2025-10-06 23:33:18.829019+05:30
813	\N	95	35	2025-08-12	2025-08-16	Checked-Out	19800.00	10.00	0.00	0.00	Card	7920.00	2025-10-06 23:33:18.829019+05:30
749	\N	12	32	2025-09-22	2025-09-23	Checked-Out	19800.00	10.00	2365.63	0.00	Online	1980.00	2025-10-06 23:33:18.829019+05:30
766	\N	6	33	2025-09-07	2025-09-09	Checked-In	19800.00	10.00	3850.91	0.00	Online	3960.00	2025-10-06 23:33:18.829019+05:30
777	\N	148	34	2025-07-12	2025-07-13	Checked-Out	19440.00	10.00	1302.52	0.00	Online	1944.00	2025-10-06 23:33:18.829019+05:30
779	\N	133	34	2025-07-15	2025-07-16	Checked-Out	18000.00	10.00	2523.36	0.00	Card	1800.00	2025-10-06 23:33:18.829019+05:30
788	\N	95	34	2025-08-12	2025-08-14	Checked-Out	19800.00	10.00	2712.43	0.00	Card	3960.00	2025-10-06 23:33:18.829019+05:30
799	\N	78	34	2025-09-26	2025-09-28	Checked-Out	21384.00	10.00	3531.60	0.00	Online	4276.80	2025-10-06 23:33:18.829019+05:30
776	\N	15	34	2025-07-09	2025-07-11	Checked-Out	18000.00	10.00	1418.27	0.00	Cash	3600.00	2025-10-06 23:33:18.829019+05:30
791	\N	135	34	2025-08-20	2025-08-24	Checked-Out	19800.00	10.00	1950.51	0.00	Online	7920.00	2025-10-06 23:33:18.829019+05:30
806	\N	134	35	2025-07-18	2025-07-23	Checked-Out	19440.00	10.00	1441.53	0.00	BankTransfer	9720.00	2025-10-06 23:33:18.829019+05:30
740	\N	7	32	2025-08-15	2025-08-20	Checked-Out	21384.00	10.00	2626.72	0.00	BankTransfer	10692.00	2025-10-06 23:33:18.829019+05:30
741	\N	140	32	2025-08-20	2025-08-23	Checked-Out	19800.00	10.00	2432.15	0.00	Card	5940.00	2025-10-06 23:33:18.829019+05:30
768	\N	61	33	2025-09-14	2025-09-17	Checked-Out	19800.00	10.00	2432.15	0.00	BankTransfer	5940.00	2025-10-06 23:33:18.829019+05:30
772	\N	30	33	2025-09-30	2025-10-01	Checked-In	19800.00	10.00	2432.15	0.00	Cash	1980.00	2025-10-06 23:33:18.829019+05:30
747	\N	28	32	2025-09-12	2025-09-15	Checked-Out	21384.00	10.00	0.00	4511.18	Cash	6415.20	2025-10-06 23:33:18.829019+05:30
802	\N	99	35	2025-07-05	2025-07-08	Checked-Out	19440.00	10.00	2387.93	0.00	Card	5832.00	2025-10-06 23:33:18.829019+05:30
735	\N	72	32	2025-07-30	2025-08-01	Cancelled	18000.00	10.00	0.00	0.00	Cash	3600.00	2025-10-06 23:33:18.829019+05:30
736	\N	73	32	2025-08-01	2025-08-05	Cancelled	21384.00	10.00	0.00	0.00	Online	8553.60	2025-10-06 23:33:18.829019+05:30
783	\N	51	34	2025-07-27	2025-08-01	Cancelled	18000.00	10.00	2211.05	0.00	Online	9000.00	2025-10-06 23:33:18.829019+05:30
751	\N	78	32	2025-09-30	2025-10-03	Checked-In	19800.00	10.00	0.00	3413.81	Online	5940.00	2025-10-06 23:33:18.829019+05:30
752	\N	55	33	2025-07-01	2025-07-04	Checked-Out	18000.00	10.00	0.00	4647.52	BankTransfer	5400.00	2025-10-06 23:33:18.829019+05:30
765	\N	47	33	2025-09-05	2025-09-07	Checked-Out	21384.00	10.00	0.00	4290.09	Card	4276.80	2025-10-06 23:33:18.829019+05:30
767	\N	37	33	2025-09-10	2025-09-12	Checked-Out	19800.00	10.00	0.00	3567.64	Card	3960.00	2025-10-06 23:33:18.829019+05:30
796	\N	103	34	2025-09-13	2025-09-15	Checked-Out	21384.00	10.00	0.00	4807.70	Card	4276.80	2025-10-06 23:33:18.829019+05:30
816	\N	128	35	2025-08-25	2025-08-27	Checked-Out	19800.00	10.00	0.00	0.00	Online	3960.00	2025-10-06 23:33:18.829019+05:30
818	\N	45	35	2025-09-01	2025-09-06	Checked-Out	19800.00	10.00	0.00	0.00	Cash	9900.00	2025-10-06 23:33:18.829019+05:30
819	\N	29	35	2025-09-06	2025-09-09	Checked-Out	21384.00	10.00	0.00	0.00	Online	6415.20	2025-10-06 23:33:18.829019+05:30
820	\N	80	35	2025-09-11	2025-09-14	Checked-In	19800.00	10.00	0.00	0.00	Card	5940.00	2025-10-06 23:33:18.829019+05:30
822	\N	23	35	2025-09-21	2025-09-25	Checked-In	19800.00	10.00	0.00	0.00	Cash	7920.00	2025-10-06 23:33:18.829019+05:30
823	\N	18	35	2025-09-25	2025-09-26	Checked-Out	19800.00	10.00	0.00	0.00	Cash	1980.00	2025-10-06 23:33:18.829019+05:30
824	\N	66	35	2025-09-26	2025-09-28	Checked-Out	21384.00	10.00	0.00	0.00	Card	4276.80	2025-10-06 23:33:18.829019+05:30
825	\N	77	35	2025-09-28	2025-09-29	Checked-Out	19800.00	10.00	0.00	0.00	Card	1980.00	2025-10-06 23:33:18.829019+05:30
826	\N	135	35	2025-09-29	2025-10-03	Checked-Out	19800.00	10.00	0.00	0.00	Card	7920.00	2025-10-06 23:33:18.829019+05:30
827	\N	93	36	2025-07-01	2025-07-04	Checked-Out	12000.00	10.00	0.00	0.00	Online	3600.00	2025-10-06 23:33:18.829019+05:30
830	\N	72	36	2025-07-11	2025-07-13	Checked-Out	12960.00	10.00	0.00	0.00	Online	2592.00	2025-10-06 23:33:18.829019+05:30
831	\N	22	36	2025-07-14	2025-07-17	Checked-Out	12000.00	10.00	0.00	0.00	Cash	3600.00	2025-10-06 23:33:18.829019+05:30
832	\N	110	36	2025-07-17	2025-07-20	Checked-Out	12000.00	10.00	0.00	0.00	Cash	3600.00	2025-10-06 23:33:18.829019+05:30
833	\N	104	36	2025-07-21	2025-07-24	Checked-Out	12000.00	10.00	0.00	0.00	BankTransfer	3600.00	2025-10-06 23:33:18.829019+05:30
838	\N	28	36	2025-08-07	2025-08-08	Checked-Out	13200.00	10.00	0.00	0.00	Online	1320.00	2025-10-06 23:33:18.829019+05:30
840	\N	144	36	2025-08-13	2025-08-16	Checked-Out	13200.00	10.00	0.00	0.00	Card	3960.00	2025-10-06 23:33:18.829019+05:30
842	\N	147	36	2025-08-22	2025-08-26	Checked-Out	14256.00	10.00	0.00	0.00	Online	5702.40	2025-10-06 23:33:18.829019+05:30
845	\N	88	36	2025-09-05	2025-09-10	Checked-Out	14256.00	10.00	0.00	0.00	Online	7128.00	2025-10-06 23:33:18.829019+05:30
847	\N	43	36	2025-09-16	2025-09-18	Checked-Out	13200.00	10.00	0.00	0.00	Online	2640.00	2025-10-06 23:33:18.829019+05:30
849	\N	14	36	2025-09-23	2025-09-26	Checked-Out	13200.00	10.00	0.00	0.00	Cash	3960.00	2025-10-06 23:33:18.829019+05:30
850	\N	46	36	2025-09-26	2025-09-29	Checked-Out	14256.00	10.00	0.00	0.00	Cash	4276.80	2025-10-06 23:33:18.829019+05:30
855	\N	56	37	2025-07-12	2025-07-15	Checked-Out	12960.00	10.00	0.00	0.00	Cash	3888.00	2025-10-06 23:33:18.829019+05:30
856	\N	35	37	2025-07-15	2025-07-20	Checked-Out	12000.00	10.00	0.00	0.00	BankTransfer	6000.00	2025-10-06 23:33:18.829019+05:30
858	\N	96	37	2025-07-25	2025-07-29	Checked-Out	12960.00	10.00	0.00	0.00	BankTransfer	5184.00	2025-10-06 23:33:18.829019+05:30
860	\N	147	37	2025-08-04	2025-08-06	Checked-Out	13200.00	10.00	0.00	0.00	Cash	2640.00	2025-10-06 23:33:18.829019+05:30
861	\N	115	37	2025-08-08	2025-08-13	Checked-Out	14256.00	10.00	0.00	0.00	BankTransfer	7128.00	2025-10-06 23:33:18.829019+05:30
862	\N	65	37	2025-08-13	2025-08-16	Checked-Out	13200.00	10.00	0.00	0.00	BankTransfer	3960.00	2025-10-06 23:33:18.829019+05:30
863	\N	149	37	2025-08-16	2025-08-20	Checked-In	14256.00	10.00	0.00	0.00	Card	5702.40	2025-10-06 23:33:18.829019+05:30
865	\N	73	37	2025-08-23	2025-08-26	Checked-Out	14256.00	10.00	0.00	0.00	Cash	4276.80	2025-10-06 23:33:18.829019+05:30
870	\N	136	37	2025-09-11	2025-09-14	Checked-Out	13200.00	10.00	0.00	0.00	Cash	3960.00	2025-10-06 23:33:18.829019+05:30
871	\N	73	37	2025-09-16	2025-09-18	Checked-Out	13200.00	10.00	0.00	0.00	BankTransfer	2640.00	2025-10-06 23:33:18.829019+05:30
872	\N	27	37	2025-09-19	2025-09-21	Checked-Out	14256.00	10.00	0.00	0.00	Online	2851.20	2025-10-06 23:33:18.829019+05:30
873	\N	133	37	2025-09-22	2025-09-24	Checked-Out	13200.00	10.00	0.00	0.00	BankTransfer	2640.00	2025-10-06 23:33:18.829019+05:30
1056	\N	84	45	2025-09-18	2025-09-22	Checked-Out	26400.00	10.00	0.00	0.00	Cash	10560.00	2025-10-06 23:33:18.829019+05:30
1057	\N	147	45	2025-09-23	2025-09-25	Checked-Out	26400.00	10.00	0.00	0.00	Online	5280.00	2025-10-06 23:33:18.829019+05:30
1058	\N	129	45	2025-09-27	2025-10-01	Checked-Out	28512.00	10.00	0.00	0.00	Online	11404.80	2025-10-06 23:33:18.829019+05:30
874	\N	45	37	2025-09-25	2025-09-29	Checked-Out	13200.00	10.00	0.00	0.00	Cash	5280.00	2025-10-06 23:33:18.829019+05:30
876	\N	28	38	2025-07-01	2025-07-05	Checked-In	12000.00	10.00	0.00	0.00	Cash	4800.00	2025-10-06 23:33:18.829019+05:30
877	\N	21	38	2025-07-05	2025-07-08	Checked-Out	12960.00	10.00	0.00	0.00	BankTransfer	3888.00	2025-10-06 23:33:18.829019+05:30
878	\N	142	38	2025-07-09	2025-07-13	Checked-In	12000.00	10.00	0.00	0.00	BankTransfer	4800.00	2025-10-06 23:33:18.829019+05:30
879	\N	103	38	2025-07-14	2025-07-15	Checked-Out	12000.00	10.00	0.00	0.00	Card	1200.00	2025-10-06 23:33:18.829019+05:30
880	\N	13	38	2025-07-17	2025-07-20	Checked-Out	12000.00	10.00	0.00	0.00	BankTransfer	3600.00	2025-10-06 23:33:18.829019+05:30
881	\N	26	38	2025-07-21	2025-07-26	Checked-Out	12000.00	10.00	0.00	0.00	Online	6000.00	2025-10-06 23:33:18.829019+05:30
885	\N	11	38	2025-08-03	2025-08-05	Checked-Out	13200.00	10.00	0.00	0.00	Card	2640.00	2025-10-06 23:33:18.829019+05:30
886	\N	147	38	2025-08-05	2025-08-07	Checked-Out	13200.00	10.00	0.00	0.00	Online	2640.00	2025-10-06 23:33:18.829019+05:30
892	\N	81	38	2025-08-24	2025-08-29	Checked-Out	13200.00	10.00	0.00	0.00	Cash	6600.00	2025-10-06 23:33:18.829019+05:30
893	\N	88	38	2025-08-30	2025-09-02	Checked-Out	14256.00	10.00	0.00	0.00	Cash	4276.80	2025-10-06 23:33:18.829019+05:30
894	\N	59	38	2025-09-04	2025-09-08	Checked-In	13200.00	10.00	0.00	0.00	BankTransfer	5280.00	2025-10-06 23:33:18.829019+05:30
895	\N	28	38	2025-09-09	2025-09-12	Checked-Out	13200.00	10.00	0.00	0.00	BankTransfer	3960.00	2025-10-06 23:33:18.829019+05:30
852	\N	106	37	2025-07-01	2025-07-04	Checked-Out	12000.00	10.00	1112.58	0.00	Cash	3600.00	2025-10-06 23:33:18.829019+05:30
839	\N	124	36	2025-08-10	2025-08-12	Checked-Out	13200.00	10.00	1621.43	0.00	Card	2640.00	2025-10-06 23:33:18.829019+05:30
869	\N	76	37	2025-09-06	2025-09-10	Checked-Out	14256.00	10.00	1226.68	0.00	Cash	5702.40	2025-10-06 23:33:18.829019+05:30
875	\N	81	37	2025-09-29	2025-10-04	Checked-In	13200.00	10.00	687.19	0.00	Cash	6600.00	2025-10-06 23:33:18.829019+05:30
815	\N	5	35	2025-08-21	2025-08-24	Checked-Out	19800.00	10.00	2307.45	0.00	BankTransfer	5940.00	2025-10-06 23:33:18.829019+05:30
828	\N	2	36	2025-07-05	2025-07-08	Checked-Out	12960.00	10.00	2299.07	0.00	Cash	3888.00	2025-10-06 23:33:18.829019+05:30
882	\N	57	38	2025-07-27	2025-07-29	Cancelled	12000.00	10.00	0.00	0.00	BankTransfer	2400.00	2025-10-06 23:33:18.829019+05:30
841	\N	52	36	2025-08-16	2025-08-21	Checked-Out	14256.00	10.00	2695.84	0.00	Online	7128.00	2025-10-06 23:33:18.829019+05:30
844	\N	129	36	2025-09-02	2025-09-03	Checked-In	13200.00	10.00	972.30	0.00	Cash	1320.00	2025-10-06 23:33:18.829019+05:30
854	\N	18	37	2025-07-08	2025-07-11	Checked-Out	12000.00	10.00	1474.03	0.00	Card	3600.00	2025-10-06 23:33:18.829019+05:30
866	\N	84	37	2025-08-27	2025-09-01	Checked-Out	13200.00	10.00	1621.43	0.00	Cash	6600.00	2025-10-06 23:33:18.829019+05:30
867	\N	141	37	2025-09-02	2025-09-03	Checked-Out	13200.00	10.00	1621.43	0.00	Online	1320.00	2025-10-06 23:33:18.829019+05:30
883	\N	93	38	2025-07-30	2025-07-31	Checked-Out	12000.00	10.00	1474.03	0.00	Online	1200.00	2025-10-06 23:33:18.829019+05:30
890	\N	61	38	2025-08-19	2025-08-21	Checked-In	13200.00	10.00	1621.43	0.00	Cash	2640.00	2025-10-06 23:33:18.829019+05:30
837	\N	3	36	2025-08-01	2025-08-06	Checked-Out	14256.00	10.00	1751.15	0.00	Cash	7128.00	2025-10-06 23:33:18.829019+05:30
884	\N	148	38	2025-08-01	2025-08-03	Cancelled	14256.00	10.00	0.00	0.00	Card	2851.20	2025-10-06 23:33:18.829019+05:30
817	\N	29	35	2025-08-27	2025-08-31	Checked-Out	19800.00	10.00	0.00	2621.12	Online	7920.00	2025-10-06 23:33:18.829019+05:30
821	\N	65	35	2025-09-15	2025-09-19	Checked-Out	19800.00	10.00	0.00	5707.30	Cash	7920.00	2025-10-06 23:33:18.829019+05:30
835	\N	110	36	2025-07-27	2025-07-28	Checked-In	12000.00	10.00	0.00	1860.87	Online	1200.00	2025-10-06 23:33:18.829019+05:30
836	\N	40	36	2025-07-29	2025-07-31	Checked-In	12000.00	10.00	0.00	2687.18	Card	2400.00	2025-10-06 23:33:18.829019+05:30
851	\N	52	36	2025-09-30	2025-10-03	Checked-Out	13200.00	10.00	0.00	3944.41	Cash	3960.00	2025-10-06 23:33:18.829019+05:30
857	\N	108	37	2025-07-21	2025-07-23	Checked-In	12000.00	10.00	0.00	3416.32	Online	2400.00	2025-10-06 23:33:18.829019+05:30
864	\N	131	37	2025-08-21	2025-08-23	Checked-Out	13200.00	10.00	0.00	2420.11	Online	2640.00	2025-10-06 23:33:18.829019+05:30
898	\N	85	38	2025-09-21	2025-09-23	Checked-Out	13200.00	10.00	0.00	0.00	Cash	2640.00	2025-10-06 23:33:18.829019+05:30
899	\N	29	38	2025-09-24	2025-09-27	Checked-Out	13200.00	10.00	0.00	0.00	Online	3960.00	2025-10-06 23:33:18.829019+05:30
901	\N	144	39	2025-07-01	2025-07-04	Checked-In	12000.00	10.00	0.00	0.00	BankTransfer	3600.00	2025-10-06 23:33:18.829019+05:30
903	\N	103	39	2025-07-11	2025-07-15	Checked-In	12960.00	10.00	0.00	0.00	Card	5184.00	2025-10-06 23:33:18.829019+05:30
905	\N	145	39	2025-07-19	2025-07-20	Checked-Out	12960.00	10.00	0.00	0.00	BankTransfer	1296.00	2025-10-06 23:33:18.829019+05:30
906	\N	78	39	2025-07-21	2025-07-26	Checked-Out	12000.00	10.00	0.00	0.00	Online	6000.00	2025-10-06 23:33:18.829019+05:30
909	\N	108	39	2025-08-05	2025-08-08	Checked-Out	13200.00	10.00	0.00	0.00	BankTransfer	3960.00	2025-10-06 23:33:18.829019+05:30
910	\N	103	39	2025-08-09	2025-08-10	Checked-Out	14256.00	10.00	0.00	0.00	Online	1425.60	2025-10-06 23:33:18.829019+05:30
912	\N	66	39	2025-08-15	2025-08-20	Checked-Out	14256.00	10.00	0.00	0.00	Online	7128.00	2025-10-06 23:33:18.829019+05:30
913	\N	28	39	2025-08-20	2025-08-24	Checked-Out	13200.00	10.00	0.00	0.00	Online	5280.00	2025-10-06 23:33:18.829019+05:30
914	\N	91	39	2025-08-26	2025-08-30	Checked-Out	13200.00	10.00	0.00	0.00	Online	5280.00	2025-10-06 23:33:18.829019+05:30
915	\N	21	39	2025-09-01	2025-09-04	Checked-In	13200.00	10.00	0.00	0.00	Online	3960.00	2025-10-06 23:33:18.829019+05:30
916	\N	2	39	2025-09-04	2025-09-08	Checked-In	13200.00	10.00	0.00	0.00	BankTransfer	5280.00	2025-10-06 23:33:18.829019+05:30
918	\N	17	39	2025-09-12	2025-09-16	Checked-In	14256.00	10.00	0.00	0.00	Card	5702.40	2025-10-06 23:33:18.829019+05:30
920	\N	48	39	2025-09-22	2025-09-27	Checked-Out	13200.00	10.00	0.00	0.00	BankTransfer	6600.00	2025-10-06 23:33:18.829019+05:30
921	\N	23	39	2025-09-27	2025-09-30	Checked-Out	14256.00	10.00	0.00	0.00	Cash	4276.80	2025-10-06 23:33:18.829019+05:30
923	\N	89	40	2025-07-04	2025-07-07	Checked-Out	12960.00	10.00	0.00	0.00	Cash	3888.00	2025-10-06 23:33:18.829019+05:30
924	\N	7	40	2025-07-07	2025-07-10	Checked-Out	12000.00	10.00	0.00	0.00	BankTransfer	3600.00	2025-10-06 23:33:18.829019+05:30
926	\N	61	40	2025-07-13	2025-07-16	Checked-Out	12000.00	10.00	0.00	0.00	BankTransfer	3600.00	2025-10-06 23:33:18.829019+05:30
927	\N	92	40	2025-07-17	2025-07-21	Checked-Out	12000.00	10.00	0.00	0.00	Card	4800.00	2025-10-06 23:33:18.829019+05:30
930	\N	68	40	2025-07-31	2025-08-02	Checked-Out	12000.00	10.00	0.00	0.00	Cash	2400.00	2025-10-06 23:33:18.829019+05:30
931	\N	112	40	2025-08-02	2025-08-07	Checked-Out	14256.00	10.00	0.00	0.00	Online	7128.00	2025-10-06 23:33:18.829019+05:30
933	\N	9	40	2025-08-11	2025-08-16	Checked-Out	13200.00	10.00	0.00	0.00	Online	6600.00	2025-10-06 23:33:18.829019+05:30
935	\N	55	40	2025-08-23	2025-08-26	Checked-Out	14256.00	10.00	0.00	0.00	BankTransfer	4276.80	2025-10-06 23:33:18.829019+05:30
936	\N	42	40	2025-08-27	2025-08-29	Checked-Out	13200.00	10.00	0.00	0.00	Online	2640.00	2025-10-06 23:33:18.829019+05:30
937	\N	54	40	2025-08-31	2025-09-02	Checked-Out	13200.00	10.00	0.00	0.00	Cash	2640.00	2025-10-06 23:33:18.829019+05:30
1443	\N	1	20	2025-11-10	2025-11-12	Booked	20000.00	10.00	0.00	0.00	\N	5000.00	2025-10-07 15:40:18.738716+05:30
1127	\N	69	48	2025-09-04	2025-09-07	Checked-Out	26400.00	10.00	0.00	0.00	Cash	7920.00	2025-10-06 23:33:18.829019+05:30
1129	\N	81	48	2025-09-11	2025-09-12	Checked-In	26400.00	10.00	0.00	0.00	Card	2640.00	2025-10-06 23:33:18.829019+05:30
938	\N	44	40	2025-09-04	2025-09-08	Checked-Out	13200.00	10.00	0.00	0.00	BankTransfer	5280.00	2025-10-06 23:33:18.829019+05:30
939	\N	9	40	2025-09-09	2025-09-11	Checked-Out	13200.00	10.00	0.00	0.00	Online	2640.00	2025-10-06 23:33:18.829019+05:30
942	\N	19	40	2025-09-19	2025-09-23	Checked-Out	14256.00	10.00	0.00	0.00	Card	5702.40	2025-10-06 23:33:18.829019+05:30
943	\N	63	40	2025-09-24	2025-09-28	Checked-Out	13200.00	10.00	0.00	0.00	Online	5280.00	2025-10-06 23:33:18.829019+05:30
944	\N	117	40	2025-09-30	2025-10-03	Checked-Out	13200.00	10.00	0.00	0.00	Cash	3960.00	2025-10-06 23:33:18.829019+05:30
946	\N	46	41	2025-07-07	2025-07-11	Checked-Out	40000.00	10.00	0.00	0.00	Card	16000.00	2025-10-06 23:33:18.829019+05:30
947	\N	63	41	2025-07-12	2025-07-15	Checked-Out	43200.00	10.00	0.00	0.00	BankTransfer	12960.00	2025-10-06 23:33:18.829019+05:30
949	\N	20	41	2025-07-17	2025-07-19	Checked-In	40000.00	10.00	0.00	0.00	Cash	8000.00	2025-10-06 23:33:18.829019+05:30
950	\N	29	41	2025-07-19	2025-07-21	Checked-Out	43200.00	10.00	0.00	0.00	Cash	8640.00	2025-10-06 23:33:18.829019+05:30
951	\N	19	41	2025-07-23	2025-07-26	Checked-Out	40000.00	10.00	0.00	0.00	BankTransfer	12000.00	2025-10-06 23:33:18.829019+05:30
953	\N	86	41	2025-07-29	2025-07-31	Checked-Out	40000.00	10.00	0.00	0.00	Card	8000.00	2025-10-06 23:33:18.829019+05:30
954	\N	98	41	2025-08-02	2025-08-07	Checked-Out	47520.00	10.00	0.00	0.00	Online	23760.00	2025-10-06 23:33:18.829019+05:30
955	\N	27	41	2025-08-09	2025-08-12	Checked-In	47520.00	10.00	0.00	0.00	Cash	14256.00	2025-10-06 23:33:18.829019+05:30
967	\N	31	41	2025-09-28	2025-10-01	Checked-Out	44000.00	10.00	0.00	0.00	Online	13200.00	2025-10-06 23:33:18.829019+05:30
969	\N	8	42	2025-07-03	2025-07-07	Checked-Out	40000.00	10.00	0.00	0.00	Online	16000.00	2025-10-06 23:33:18.829019+05:30
970	\N	112	42	2025-07-08	2025-07-13	Checked-Out	40000.00	10.00	0.00	0.00	BankTransfer	20000.00	2025-10-06 23:33:18.829019+05:30
971	\N	76	42	2025-07-14	2025-07-17	Checked-Out	40000.00	10.00	0.00	0.00	Online	12000.00	2025-10-06 23:33:18.829019+05:30
972	\N	135	42	2025-07-18	2025-07-20	Checked-Out	43200.00	10.00	0.00	0.00	BankTransfer	8640.00	2025-10-06 23:33:18.829019+05:30
975	\N	47	42	2025-07-31	2025-08-03	Checked-Out	40000.00	10.00	0.00	0.00	Online	12000.00	2025-10-06 23:33:18.829019+05:30
977	\N	91	42	2025-08-09	2025-08-13	Checked-Out	47520.00	10.00	0.00	0.00	Cash	19008.00	2025-10-06 23:33:18.829019+05:30
902	\N	39	39	2025-07-06	2025-07-10	Checked-Out	12000.00	10.00	811.50	0.00	Cash	4800.00	2025-10-06 23:33:18.829019+05:30
904	\N	46	39	2025-07-15	2025-07-18	Checked-In	12000.00	10.00	640.91	0.00	Online	3600.00	2025-10-06 23:33:18.829019+05:30
925	\N	20	40	2025-07-10	2025-07-12	Checked-Out	12000.00	10.00	1707.49	0.00	Online	2400.00	2025-10-06 23:33:18.829019+05:30
928	\N	137	40	2025-07-22	2025-07-26	Checked-Out	12000.00	10.00	890.54	0.00	BankTransfer	4800.00	2025-10-06 23:33:18.829019+05:30
958	\N	28	41	2025-08-20	2025-08-23	Checked-Out	44000.00	10.00	5024.41	0.00	Online	13200.00	2025-10-06 23:33:18.829019+05:30
960	\N	24	41	2025-08-28	2025-08-29	Checked-Out	44000.00	10.00	6589.13	0.00	Cash	4400.00	2025-10-06 23:33:18.829019+05:30
966	\N	5	41	2025-09-23	2025-09-26	Checked-Out	44000.00	10.00	5997.35	0.00	BankTransfer	13200.00	2025-10-06 23:33:18.829019+05:30
917	\N	124	39	2025-09-08	2025-09-11	Checked-In	13200.00	10.00	0.00	2007.04	BankTransfer	3960.00	2025-10-06 23:33:18.829019+05:30
919	\N	126	39	2025-09-17	2025-09-21	Checked-Out	13200.00	10.00	779.13	0.00	Online	5280.00	2025-10-06 23:33:18.829019+05:30
934	\N	6	40	2025-08-18	2025-08-23	Checked-Out	13200.00	10.00	1552.38	0.00	Cash	6600.00	2025-10-06 23:33:18.829019+05:30
945	\N	62	41	2025-07-01	2025-07-05	Checked-Out	40000.00	10.00	4870.49	0.00	Cash	16000.00	2025-10-06 23:33:18.829019+05:30
897	\N	59	38	2025-09-16	2025-09-20	Checked-In	13200.00	10.00	1621.43	0.00	Online	5280.00	2025-10-06 23:33:18.829019+05:30
948	\N	30	41	2025-07-16	2025-07-17	Checked-In	40000.00	10.00	4913.43	0.00	Cash	4000.00	2025-10-06 23:33:18.829019+05:30
964	\N	98	41	2025-09-12	2025-09-14	Checked-In	47520.00	10.00	5837.16	0.00	Cash	9504.00	2025-10-06 23:33:18.829019+05:30
908	\N	103	39	2025-08-02	2025-08-03	Cancelled	14256.00	10.00	0.00	0.00	Cash	1425.60	2025-10-06 23:33:18.829019+05:30
941	\N	62	40	2025-09-15	2025-09-18	Cancelled	13200.00	10.00	0.00	0.00	Cash	3960.00	2025-10-06 23:33:18.829019+05:30
900	\N	62	38	2025-09-29	2025-10-01	Cancelled	13200.00	10.00	2097.68	0.00	Card	2640.00	2025-10-06 23:33:18.829019+05:30
959	\N	53	41	2025-08-24	2025-08-26	Checked-Out	44000.00	10.00	0.00	10725.51	Cash	8800.00	2025-10-06 23:33:18.829019+05:30
968	\N	133	42	2025-07-01	2025-07-02	Checked-Out	40000.00	10.00	0.00	11630.91	Card	4000.00	2025-10-06 23:33:18.829019+05:30
976	\N	78	42	2025-08-04	2025-08-09	Checked-Out	44000.00	10.00	0.00	12829.50	Online	22000.00	2025-10-06 23:33:18.829019+05:30
981	\N	109	42	2025-08-26	2025-08-31	Checked-Out	44000.00	10.00	0.00	0.00	Cash	22000.00	2025-10-06 23:33:18.829019+05:30
982	\N	20	42	2025-08-31	2025-09-02	Checked-Out	44000.00	10.00	0.00	0.00	Cash	8800.00	2025-10-06 23:33:18.829019+05:30
983	\N	53	42	2025-09-03	2025-09-08	Checked-Out	44000.00	10.00	0.00	0.00	Online	22000.00	2025-10-06 23:33:18.829019+05:30
987	\N	149	42	2025-09-26	2025-09-27	Checked-Out	47520.00	10.00	0.00	0.00	Online	4752.00	2025-10-06 23:33:18.829019+05:30
989	\N	17	43	2025-07-01	2025-07-05	Checked-Out	40000.00	10.00	0.00	0.00	BankTransfer	16000.00	2025-10-06 23:33:18.829019+05:30
992	\N	126	43	2025-07-11	2025-07-14	Checked-Out	43200.00	10.00	0.00	0.00	Cash	12960.00	2025-10-06 23:33:18.829019+05:30
994	\N	68	43	2025-07-18	2025-07-23	Checked-Out	43200.00	10.00	0.00	0.00	BankTransfer	21600.00	2025-10-06 23:33:18.829019+05:30
995	\N	62	43	2025-07-24	2025-07-26	Checked-Out	40000.00	10.00	0.00	0.00	Cash	8000.00	2025-10-06 23:33:18.829019+05:30
997	\N	59	43	2025-08-01	2025-08-05	Checked-Out	47520.00	10.00	0.00	0.00	Cash	19008.00	2025-10-06 23:33:18.829019+05:30
998	\N	140	43	2025-08-05	2025-08-06	Checked-Out	44000.00	10.00	0.00	0.00	Online	4400.00	2025-10-06 23:33:18.829019+05:30
1000	\N	110	43	2025-08-14	2025-08-16	Checked-Out	44000.00	10.00	0.00	0.00	Cash	8800.00	2025-10-06 23:33:18.829019+05:30
1004	\N	124	43	2025-09-03	2025-09-04	Checked-In	44000.00	10.00	0.00	0.00	Cash	4400.00	2025-10-06 23:33:18.829019+05:30
1008	\N	117	43	2025-09-17	2025-09-19	Checked-Out	44000.00	10.00	0.00	0.00	Cash	8800.00	2025-10-06 23:33:18.829019+05:30
1010	\N	63	43	2025-09-24	2025-09-27	Checked-Out	44000.00	10.00	0.00	0.00	Card	13200.00	2025-10-06 23:33:18.829019+05:30
1011	\N	82	43	2025-09-28	2025-10-01	Checked-In	44000.00	10.00	0.00	0.00	BankTransfer	13200.00	2025-10-06 23:33:18.829019+05:30
1012	\N	76	44	2025-07-01	2025-07-02	Checked-Out	24000.00	10.00	0.00	0.00	Card	2400.00	2025-10-06 23:33:18.829019+05:30
1013	\N	44	44	2025-07-04	2025-07-09	Checked-Out	25920.00	10.00	0.00	0.00	Online	12960.00	2025-10-06 23:33:18.829019+05:30
1017	\N	20	44	2025-07-27	2025-07-29	Checked-In	24000.00	10.00	0.00	0.00	BankTransfer	4800.00	2025-10-06 23:33:18.829019+05:30
1020	\N	3	44	2025-08-06	2025-08-10	Checked-Out	26400.00	10.00	0.00	0.00	Cash	10560.00	2025-10-06 23:33:18.829019+05:30
1021	\N	41	44	2025-08-10	2025-08-15	Checked-Out	26400.00	10.00	0.00	0.00	BankTransfer	13200.00	2025-10-06 23:33:18.829019+05:30
1022	\N	74	44	2025-08-16	2025-08-18	Checked-Out	28512.00	10.00	0.00	0.00	Online	5702.40	2025-10-06 23:33:18.829019+05:30
1024	\N	52	44	2025-08-23	2025-08-28	Checked-Out	28512.00	10.00	0.00	0.00	Online	14256.00	2025-10-06 23:33:18.829019+05:30
1026	\N	139	44	2025-09-01	2025-09-05	Checked-Out	26400.00	10.00	0.00	0.00	Cash	10560.00	2025-10-06 23:33:18.829019+05:30
1035	\N	34	45	2025-07-05	2025-07-06	Checked-Out	25920.00	10.00	0.00	0.00	Online	2592.00	2025-10-06 23:33:18.829019+05:30
1036	\N	26	45	2025-07-07	2025-07-10	Checked-Out	24000.00	10.00	0.00	0.00	BankTransfer	7200.00	2025-10-06 23:33:18.829019+05:30
1037	\N	120	45	2025-07-10	2025-07-14	Checked-Out	24000.00	10.00	0.00	0.00	Cash	9600.00	2025-10-06 23:33:18.829019+05:30
1041	\N	135	45	2025-07-23	2025-07-25	Checked-In	24000.00	10.00	0.00	0.00	Card	4800.00	2025-10-06 23:33:18.829019+05:30
1042	\N	11	45	2025-07-26	2025-07-29	Checked-Out	25920.00	10.00	0.00	0.00	Cash	7776.00	2025-10-06 23:33:18.829019+05:30
1043	\N	105	45	2025-07-29	2025-08-01	Checked-Out	24000.00	10.00	0.00	0.00	Online	7200.00	2025-10-06 23:33:18.829019+05:30
1044	\N	113	45	2025-08-02	2025-08-04	Checked-Out	28512.00	10.00	0.00	0.00	Online	5702.40	2025-10-06 23:33:18.829019+05:30
1045	\N	36	45	2025-08-04	2025-08-09	Checked-Out	26400.00	10.00	0.00	0.00	Card	13200.00	2025-10-06 23:33:18.829019+05:30
1047	\N	8	45	2025-08-12	2025-08-17	Checked-Out	26400.00	10.00	0.00	0.00	BankTransfer	13200.00	2025-10-06 23:33:18.829019+05:30
1048	\N	18	45	2025-08-18	2025-08-22	Checked-Out	26400.00	10.00	0.00	0.00	Online	10560.00	2025-10-06 23:33:18.829019+05:30
1049	\N	32	45	2025-08-23	2025-08-25	Checked-Out	28512.00	10.00	0.00	0.00	Cash	5702.40	2025-10-06 23:33:18.829019+05:30
1050	\N	83	45	2025-08-25	2025-08-28	Checked-Out	26400.00	10.00	0.00	0.00	Cash	7920.00	2025-10-06 23:33:18.829019+05:30
1051	\N	47	45	2025-08-29	2025-08-30	Checked-Out	28512.00	10.00	0.00	0.00	Cash	2851.20	2025-10-06 23:33:18.829019+05:30
1055	\N	108	45	2025-09-15	2025-09-18	Checked-Out	26400.00	10.00	0.00	0.00	Cash	7920.00	2025-10-06 23:33:18.829019+05:30
1059	\N	92	46	2025-07-01	2025-07-04	Checked-In	24000.00	10.00	0.00	0.00	Online	7200.00	2025-10-06 23:33:18.829019+05:30
978	\N	19	42	2025-08-13	2025-08-15	Checked-In	44000.00	10.00	8579.07	0.00	Card	8800.00	2025-10-06 23:33:18.829019+05:30
980	\N	43	42	2025-08-21	2025-08-24	Checked-Out	44000.00	10.00	5404.78	0.00	Card	13200.00	2025-10-06 23:33:18.829019+05:30
991	\N	88	43	2025-07-09	2025-07-10	Cancelled	40000.00	10.00	0.00	0.00	Cash	4000.00	2025-10-06 23:33:18.829019+05:30
1019	\N	121	44	2025-08-03	2025-08-05	Checked-Out	26400.00	10.00	3164.42	0.00	Online	5280.00	2025-10-06 23:33:18.829019+05:30
1033	\N	32	44	2025-09-27	2025-10-01	Checked-In	28512.00	10.00	5217.89	0.00	Online	11404.80	2025-10-06 23:33:18.829019+05:30
979	\N	84	42	2025-08-16	2025-08-19	Checked-Out	47520.00	10.00	4675.76	0.00	Online	14256.00	2025-10-06 23:33:18.829019+05:30
988	\N	74	42	2025-09-29	2025-10-04	Checked-Out	44000.00	10.00	7436.89	0.00	Online	22000.00	2025-10-06 23:33:18.829019+05:30
1001	\N	91	43	2025-08-17	2025-08-22	Checked-In	44000.00	10.00	5586.14	0.00	BankTransfer	22000.00	2025-10-06 23:33:18.829019+05:30
1029	\N	137	44	2025-09-13	2025-09-15	Checked-In	28512.00	10.00	2668.71	0.00	Card	5702.40	2025-10-06 23:33:18.829019+05:30
1032	\N	132	44	2025-09-23	2025-09-26	Checked-Out	26400.00	10.00	3376.26	0.00	Online	7920.00	2025-10-06 23:33:18.829019+05:30
1034	\N	15	45	2025-07-01	2025-07-03	Checked-Out	24000.00	10.00	1265.78	0.00	Online	4800.00	2025-10-06 23:33:18.829019+05:30
1054	\N	97	45	2025-09-09	2025-09-14	Checked-Out	26400.00	10.00	4482.44	0.00	Online	13200.00	2025-10-06 23:33:18.829019+05:30
985	\N	115	42	2025-09-17	2025-09-21	Checked-Out	44000.00	10.00	5098.53	0.00	Cash	17600.00	2025-10-06 23:33:18.829019+05:30
1023	\N	113	44	2025-08-19	2025-08-22	Checked-Out	26400.00	10.00	3242.87	0.00	Card	7920.00	2025-10-06 23:33:18.829019+05:30
1046	\N	127	45	2025-08-10	2025-08-12	Checked-Out	26400.00	10.00	3242.87	0.00	Card	5280.00	2025-10-06 23:33:18.829019+05:30
1007	\N	37	43	2025-09-12	2025-09-16	Checked-Out	47520.00	10.00	5837.16	0.00	Online	19008.00	2025-10-06 23:33:18.829019+05:30
1015	\N	62	44	2025-07-17	2025-07-19	Cancelled	24000.00	10.00	0.00	0.00	Cash	4800.00	2025-10-06 23:33:18.829019+05:30
1039	\N	70	45	2025-07-19	2025-07-20	Cancelled	25920.00	10.00	0.00	0.00	Online	2592.00	2025-10-06 23:33:18.829019+05:30
1040	\N	147	45	2025-07-21	2025-07-23	Cancelled	24000.00	10.00	0.00	0.00	Cash	4800.00	2025-10-06 23:33:18.829019+05:30
1028	\N	88	44	2025-09-10	2025-09-11	Checked-Out	26400.00	10.00	0.00	6722.41	Cash	2640.00	2025-10-06 23:33:18.829019+05:30
1052	\N	134	45	2025-08-31	2025-09-04	Checked-Out	26400.00	10.00	0.00	5706.79	Cash	10560.00	2025-10-06 23:33:18.829019+05:30
986	\N	11	42	2025-09-21	2025-09-25	Checked-Out	44000.00	10.00	7972.05	5888.84	Online	17600.00	2025-10-06 23:33:18.829019+05:30
999	\N	18	43	2025-08-07	2025-08-12	Checked-Out	44000.00	10.00	5404.78	12482.77	Cash	22000.00	2025-10-06 23:33:18.829019+05:30
1060	\N	114	46	2025-07-05	2025-07-07	Checked-In	25920.00	10.00	0.00	0.00	Cash	5184.00	2025-10-06 23:33:18.829019+05:30
1062	\N	103	46	2025-07-11	2025-07-13	Checked-Out	25920.00	10.00	0.00	0.00	Online	5184.00	2025-10-06 23:33:18.829019+05:30
1063	\N	45	46	2025-07-13	2025-07-15	Checked-In	24000.00	10.00	0.00	0.00	BankTransfer	4800.00	2025-10-06 23:33:18.829019+05:30
1064	\N	47	46	2025-07-16	2025-07-18	Checked-Out	24000.00	10.00	0.00	0.00	Online	4800.00	2025-10-06 23:33:18.829019+05:30
1065	\N	145	46	2025-07-19	2025-07-20	Checked-Out	25920.00	10.00	0.00	0.00	Card	2592.00	2025-10-06 23:33:18.829019+05:30
1066	\N	122	46	2025-07-20	2025-07-23	Checked-Out	24000.00	10.00	0.00	0.00	Online	7200.00	2025-10-06 23:33:18.829019+05:30
1067	\N	128	46	2025-07-24	2025-07-27	Checked-Out	24000.00	10.00	0.00	0.00	Cash	7200.00	2025-10-06 23:33:18.829019+05:30
1068	\N	58	46	2025-07-28	2025-07-30	Checked-Out	24000.00	10.00	0.00	0.00	BankTransfer	4800.00	2025-10-06 23:33:18.829019+05:30
1071	\N	117	46	2025-08-08	2025-08-09	Checked-Out	28512.00	10.00	0.00	0.00	BankTransfer	2851.20	2025-10-06 23:33:18.829019+05:30
1075	\N	19	46	2025-08-23	2025-08-25	Checked-In	28512.00	10.00	0.00	0.00	Card	5702.40	2025-10-06 23:33:18.829019+05:30
1076	\N	82	46	2025-08-26	2025-08-28	Checked-Out	26400.00	10.00	0.00	0.00	BankTransfer	5280.00	2025-10-06 23:33:18.829019+05:30
1078	\N	19	46	2025-09-02	2025-09-07	Checked-Out	26400.00	10.00	0.00	0.00	Online	13200.00	2025-10-06 23:33:18.829019+05:30
1079	\N	85	46	2025-09-09	2025-09-11	Checked-Out	26400.00	10.00	0.00	0.00	Online	5280.00	2025-10-06 23:33:18.829019+05:30
1080	\N	122	46	2025-09-13	2025-09-18	Checked-Out	28512.00	10.00	0.00	0.00	Online	14256.00	2025-10-06 23:33:18.829019+05:30
1081	\N	4	46	2025-09-19	2025-09-22	Checked-Out	28512.00	10.00	0.00	0.00	Cash	8553.60	2025-10-06 23:33:18.829019+05:30
1082	\N	133	46	2025-09-23	2025-09-28	Checked-Out	26400.00	10.00	0.00	0.00	BankTransfer	13200.00	2025-10-06 23:33:18.829019+05:30
1083	\N	52	46	2025-09-29	2025-10-04	Checked-Out	26400.00	10.00	0.00	0.00	Online	13200.00	2025-10-06 23:33:18.829019+05:30
1086	\N	44	47	2025-07-08	2025-07-13	Checked-Out	24000.00	10.00	0.00	0.00	Cash	12000.00	2025-10-06 23:33:18.829019+05:30
1087	\N	16	47	2025-07-13	2025-07-16	Checked-In	24000.00	10.00	0.00	0.00	Online	7200.00	2025-10-06 23:33:18.829019+05:30
1090	\N	5	47	2025-07-24	2025-07-26	Checked-Out	24000.00	10.00	0.00	0.00	Card	4800.00	2025-10-06 23:33:18.829019+05:30
1093	\N	71	47	2025-08-03	2025-08-05	Checked-Out	26400.00	10.00	0.00	0.00	Cash	5280.00	2025-10-06 23:33:18.829019+05:30
1095	\N	72	47	2025-08-09	2025-08-11	Checked-Out	28512.00	10.00	0.00	0.00	Card	5702.40	2025-10-06 23:33:18.829019+05:30
1098	\N	109	47	2025-08-17	2025-08-19	Checked-Out	26400.00	10.00	0.00	0.00	BankTransfer	5280.00	2025-10-06 23:33:18.829019+05:30
1099	\N	92	47	2025-08-19	2025-08-21	Checked-In	26400.00	10.00	0.00	0.00	Card	5280.00	2025-10-06 23:33:18.829019+05:30
1100	\N	127	47	2025-08-21	2025-08-24	Checked-In	26400.00	10.00	0.00	0.00	Cash	7920.00	2025-10-06 23:33:18.829019+05:30
1101	\N	63	47	2025-08-24	2025-08-29	Checked-Out	26400.00	10.00	0.00	0.00	Cash	13200.00	2025-10-06 23:33:18.829019+05:30
1102	\N	69	47	2025-08-30	2025-09-04	Checked-Out	28512.00	10.00	0.00	0.00	Online	14256.00	2025-10-06 23:33:18.829019+05:30
1103	\N	22	47	2025-09-05	2025-09-09	Checked-Out	28512.00	10.00	0.00	0.00	Online	11404.80	2025-10-06 23:33:18.829019+05:30
1104	\N	141	47	2025-09-11	2025-09-14	Checked-Out	26400.00	10.00	0.00	0.00	Online	7920.00	2025-10-06 23:33:18.829019+05:30
1229	\N	87	52	2025-09-28	2025-09-30	Cancelled	19800.00	10.00	0.00	0.00	Cash	3960.00	2025-10-06 23:33:18.829019+05:30
1105	\N	53	47	2025-09-15	2025-09-20	Checked-Out	26400.00	10.00	0.00	0.00	Cash	13200.00	2025-10-06 23:33:18.829019+05:30
1107	\N	117	47	2025-09-24	2025-09-28	Checked-In	26400.00	10.00	0.00	0.00	Cash	10560.00	2025-10-06 23:33:18.829019+05:30
1108	\N	10	47	2025-09-29	2025-10-01	Checked-Out	26400.00	10.00	0.00	0.00	Online	5280.00	2025-10-06 23:33:18.829019+05:30
1110	\N	100	48	2025-07-04	2025-07-06	Checked-Out	25920.00	10.00	0.00	0.00	BankTransfer	5184.00	2025-10-06 23:33:18.829019+05:30
1111	\N	87	48	2025-07-08	2025-07-12	Checked-Out	24000.00	10.00	0.00	0.00	Cash	9600.00	2025-10-06 23:33:18.829019+05:30
1112	\N	144	48	2025-07-12	2025-07-15	Checked-Out	25920.00	10.00	0.00	0.00	Cash	7776.00	2025-10-06 23:33:18.829019+05:30
1113	\N	54	48	2025-07-15	2025-07-20	Checked-Out	24000.00	10.00	0.00	0.00	BankTransfer	12000.00	2025-10-06 23:33:18.829019+05:30
1116	\N	57	48	2025-07-27	2025-07-30	Checked-Out	24000.00	10.00	0.00	0.00	BankTransfer	7200.00	2025-10-06 23:33:18.829019+05:30
1117	\N	131	48	2025-07-30	2025-08-01	Checked-In	24000.00	10.00	0.00	0.00	Online	4800.00	2025-10-06 23:33:18.829019+05:30
1119	\N	1	48	2025-08-09	2025-08-11	Checked-Out	28512.00	10.00	0.00	0.00	Online	5702.40	2025-10-06 23:33:18.829019+05:30
1121	\N	53	48	2025-08-13	2025-08-14	Checked-In	26400.00	10.00	0.00	0.00	Card	2640.00	2025-10-06 23:33:18.829019+05:30
1122	\N	64	48	2025-08-15	2025-08-19	Checked-In	28512.00	10.00	0.00	0.00	Cash	11404.80	2025-10-06 23:33:18.829019+05:30
1123	\N	34	48	2025-08-20	2025-08-25	Checked-Out	26400.00	10.00	0.00	0.00	Online	13200.00	2025-10-06 23:33:18.829019+05:30
1124	\N	109	48	2025-08-26	2025-08-27	Checked-Out	26400.00	10.00	0.00	0.00	Card	2640.00	2025-10-06 23:33:18.829019+05:30
1126	\N	30	48	2025-08-31	2025-09-02	Checked-Out	26400.00	10.00	0.00	0.00	Cash	5280.00	2025-10-06 23:33:18.829019+05:30
1130	\N	1	48	2025-09-13	2025-09-16	Checked-In	28512.00	10.00	0.00	0.00	Online	8553.60	2025-10-06 23:33:18.829019+05:30
1131	\N	84	48	2025-09-16	2025-09-20	Checked-Out	26400.00	10.00	0.00	0.00	Online	10560.00	2025-10-06 23:33:18.829019+05:30
1133	\N	4	48	2025-09-23	2025-09-28	Checked-Out	26400.00	10.00	0.00	0.00	Cash	13200.00	2025-10-06 23:33:18.829019+05:30
1136	\N	118	49	2025-07-05	2025-07-07	Checked-Out	19440.00	10.00	0.00	0.00	Cash	3888.00	2025-10-06 23:33:18.829019+05:30
1137	\N	65	49	2025-07-09	2025-07-11	Checked-Out	18000.00	10.00	0.00	0.00	Cash	3600.00	2025-10-06 23:33:18.829019+05:30
1139	\N	70	49	2025-07-17	2025-07-20	Checked-In	18000.00	10.00	0.00	0.00	Cash	5400.00	2025-10-06 23:33:18.829019+05:30
1140	\N	66	49	2025-07-21	2025-07-26	Checked-Out	18000.00	10.00	0.00	0.00	Cash	9000.00	2025-10-06 23:33:18.829019+05:30
1084	\N	56	47	2025-07-01	2025-07-03	Checked-Out	24000.00	10.00	2063.12	0.00	Card	4800.00	2025-10-06 23:33:18.829019+05:30
1061	\N	8	46	2025-07-08	2025-07-10	Cancelled	24000.00	10.00	0.00	0.00	Online	4800.00	2025-10-06 23:33:18.829019+05:30
1114	\N	101	48	2025-07-20	2025-07-23	Checked-Out	24000.00	10.00	4263.05	0.00	Card	7200.00	2025-10-06 23:33:18.829019+05:30
1069	\N	93	46	2025-07-31	2025-08-03	Checked-Out	24000.00	10.00	3124.78	0.00	BankTransfer	7200.00	2025-10-06 23:33:18.829019+05:30
1109	\N	147	48	2025-07-01	2025-07-02	Checked-Out	24000.00	10.00	1824.26	0.00	Cash	2400.00	2025-10-06 23:33:18.829019+05:30
1085	\N	25	47	2025-07-04	2025-07-06	Checked-In	25920.00	10.00	3183.90	0.00	Card	5184.00	2025-10-06 23:33:18.829019+05:30
1091	\N	73	47	2025-07-27	2025-07-31	Checked-In	24000.00	10.00	2948.06	0.00	BankTransfer	9600.00	2025-10-06 23:33:18.829019+05:30
1096	\N	84	47	2025-08-12	2025-08-13	Checked-In	26400.00	10.00	3242.87	0.00	Cash	2640.00	2025-10-06 23:33:18.829019+05:30
1106	\N	102	47	2025-09-20	2025-09-23	Checked-Out	28512.00	10.00	3502.30	0.00	Online	8553.60	2025-10-06 23:33:18.829019+05:30
1135	\N	140	49	2025-07-01	2025-07-05	Checked-Out	18000.00	10.00	2211.05	0.00	Online	7200.00	2025-10-06 23:33:18.829019+05:30
1092	\N	62	47	2025-08-01	2025-08-02	Checked-In	28512.00	10.00	3502.30	0.00	Online	2851.20	2025-10-06 23:33:18.829019+05:30
1074	\N	46	46	2025-08-17	2025-08-21	Cancelled	26400.00	10.00	0.00	0.00	BankTransfer	10560.00	2025-10-06 23:33:18.829019+05:30
1077	\N	32	46	2025-08-29	2025-09-01	Cancelled	28512.00	10.00	0.00	0.00	Cash	8553.60	2025-10-06 23:33:18.829019+05:30
1097	\N	4	47	2025-08-15	2025-08-17	Cancelled	28512.00	10.00	0.00	0.00	Online	5702.40	2025-10-06 23:33:18.829019+05:30
1072	\N	41	46	2025-08-09	2025-08-11	Checked-Out	28512.00	10.00	0.00	6817.37	BankTransfer	5702.40	2025-10-06 23:33:18.829019+05:30
1089	\N	86	47	2025-07-21	2025-07-23	Checked-In	24000.00	10.00	0.00	2818.26	Cash	4800.00	2025-10-06 23:33:18.829019+05:30
1138	\N	47	49	2025-07-12	2025-07-15	Checked-Out	19440.00	10.00	0.00	5740.95	Online	5832.00	2025-10-06 23:33:18.829019+05:30
1142	\N	87	49	2025-07-31	2025-08-04	Checked-Out	18000.00	10.00	0.00	0.00	BankTransfer	7200.00	2025-10-06 23:33:18.829019+05:30
1146	\N	1	49	2025-08-13	2025-08-17	Checked-Out	19800.00	10.00	0.00	0.00	Online	7920.00	2025-10-06 23:33:18.829019+05:30
1147	\N	100	49	2025-08-19	2025-08-20	Checked-In	19800.00	10.00	0.00	0.00	Cash	1980.00	2025-10-06 23:33:18.829019+05:30
1148	\N	69	49	2025-08-22	2025-08-23	Checked-Out	21384.00	10.00	0.00	0.00	Cash	2138.40	2025-10-06 23:33:18.829019+05:30
1150	\N	144	49	2025-08-29	2025-08-31	Checked-Out	21384.00	10.00	0.00	0.00	Cash	4276.80	2025-10-06 23:33:18.829019+05:30
1152	\N	14	49	2025-09-06	2025-09-11	Checked-Out	21384.00	10.00	0.00	0.00	Card	10692.00	2025-10-06 23:33:18.829019+05:30
1153	\N	113	49	2025-09-13	2025-09-18	Checked-Out	21384.00	10.00	0.00	0.00	Online	10692.00	2025-10-06 23:33:18.829019+05:30
1154	\N	125	49	2025-09-19	2025-09-21	Checked-Out	21384.00	10.00	0.00	0.00	Online	4276.80	2025-10-06 23:33:18.829019+05:30
1156	\N	102	49	2025-09-29	2025-10-03	Checked-Out	19800.00	10.00	0.00	0.00	Online	7920.00	2025-10-06 23:33:18.829019+05:30
1159	\N	26	50	2025-07-10	2025-07-14	Checked-In	18000.00	10.00	0.00	0.00	Online	7200.00	2025-10-06 23:33:18.829019+05:30
1160	\N	125	50	2025-07-15	2025-07-17	Checked-In	18000.00	10.00	0.00	0.00	Online	3600.00	2025-10-06 23:33:18.829019+05:30
1163	\N	122	50	2025-07-25	2025-07-27	Checked-Out	19440.00	10.00	0.00	0.00	Cash	3888.00	2025-10-06 23:33:18.829019+05:30
1164	\N	40	50	2025-07-27	2025-07-29	Checked-In	18000.00	10.00	0.00	0.00	Online	3600.00	2025-10-06 23:33:18.829019+05:30
1165	\N	86	50	2025-07-30	2025-08-01	Checked-Out	18000.00	10.00	0.00	0.00	Cash	3600.00	2025-10-06 23:33:18.829019+05:30
1168	\N	127	50	2025-08-11	2025-08-13	Checked-In	19800.00	10.00	0.00	0.00	Cash	3960.00	2025-10-06 23:33:18.829019+05:30
1169	\N	20	50	2025-08-15	2025-08-19	Checked-Out	21384.00	10.00	0.00	0.00	Online	8553.60	2025-10-06 23:33:18.829019+05:30
1171	\N	29	50	2025-08-26	2025-08-30	Checked-Out	19800.00	10.00	0.00	0.00	Card	7920.00	2025-10-06 23:33:18.829019+05:30
1172	\N	42	50	2025-08-31	2025-09-03	Checked-In	19800.00	10.00	0.00	0.00	Online	5940.00	2025-10-06 23:33:18.829019+05:30
1173	\N	86	50	2025-09-03	2025-09-05	Checked-Out	19800.00	10.00	0.00	0.00	Card	3960.00	2025-10-06 23:33:18.829019+05:30
1174	\N	58	50	2025-09-05	2025-09-09	Checked-In	21384.00	10.00	0.00	0.00	Card	8553.60	2025-10-06 23:33:18.829019+05:30
1176	\N	50	50	2025-09-14	2025-09-19	Checked-Out	19800.00	10.00	0.00	0.00	Online	9900.00	2025-10-06 23:33:18.829019+05:30
1177	\N	102	50	2025-09-20	2025-09-21	Checked-Out	21384.00	10.00	0.00	0.00	Online	2138.40	2025-10-06 23:33:18.829019+05:30
1178	\N	28	50	2025-09-22	2025-09-24	Checked-Out	19800.00	10.00	0.00	0.00	Online	3960.00	2025-10-06 23:33:18.829019+05:30
1179	\N	130	50	2025-09-25	2025-09-28	Checked-Out	19800.00	10.00	0.00	0.00	BankTransfer	5940.00	2025-10-06 23:33:18.829019+05:30
1180	\N	107	50	2025-09-29	2025-10-04	Checked-Out	19800.00	10.00	0.00	0.00	Online	9900.00	2025-10-06 23:33:18.829019+05:30
1182	\N	8	51	2025-07-04	2025-07-06	Checked-Out	19440.00	10.00	0.00	0.00	Card	3888.00	2025-10-06 23:33:18.829019+05:30
1183	\N	121	51	2025-07-07	2025-07-11	Checked-Out	18000.00	10.00	0.00	0.00	Card	7200.00	2025-10-06 23:33:18.829019+05:30
1446	\N	1	1	2025-11-15	2025-11-17	Booked	20000.00	0.00	0.00	0.00	\N	10000.00	2025-10-07 19:14:43.849846+05:30
1305	\N	149	56	2025-07-21	2025-07-26	Cancelled	12000.00	10.00	0.00	0.00	Cash	6000.00	2025-10-06 23:33:18.829019+05:30
1349	\N	93	58	2025-07-24	2025-07-28	Checked-Out	12000.00	10.00	935.25	0.00	Card	4800.00	2025-10-06 23:33:18.829019+05:30
1375	\N	74	59	2025-08-10	2025-08-14	Checked-Out	13200.00	10.00	1538.92	0.00	BankTransfer	5280.00	2025-10-06 23:33:18.829019+05:30
1303	\N	19	56	2025-07-16	2025-07-18	Checked-Out	12000.00	10.00	1474.03	0.00	Card	2400.00	2025-10-06 23:33:18.829019+05:30
1324	\N	56	57	2025-07-15	2025-07-20	Checked-Out	12000.00	10.00	1474.03	0.00	Online	6000.00	2025-10-06 23:33:18.829019+05:30
1327	\N	22	57	2025-07-31	2025-08-02	Checked-Out	12000.00	10.00	1474.03	0.00	Cash	2400.00	2025-10-06 23:33:18.829019+05:30
1353	\N	105	58	2025-08-09	2025-08-13	Checked-Out	14256.00	10.00	1751.15	0.00	BankTransfer	5702.40	2025-10-06 23:33:18.829019+05:30
1373	\N	103	59	2025-08-02	2025-08-05	Checked-Out	14256.00	10.00	1751.15	0.00	BankTransfer	4276.80	2025-10-06 23:33:18.829019+05:30
1355	\N	57	58	2025-08-17	2025-08-22	Checked-Out	13200.00	10.00	0.00	3169.84	BankTransfer	6600.00	2025-10-06 23:33:18.829019+05:30
1315	\N	20	56	2025-09-08	2025-09-11	Cancelled	13200.00	10.00	0.00	0.00	Cash	3960.00	2025-10-06 23:33:18.829019+05:30
1184	\N	76	51	2025-07-13	2025-07-14	Checked-Out	18000.00	10.00	0.00	0.00	Card	1800.00	2025-10-06 23:33:18.829019+05:30
1185	\N	33	51	2025-07-15	2025-07-20	Checked-Out	18000.00	10.00	0.00	0.00	Cash	9000.00	2025-10-06 23:33:18.829019+05:30
1186	\N	112	51	2025-07-20	2025-07-24	Checked-Out	18000.00	10.00	0.00	0.00	Card	7200.00	2025-10-06 23:33:18.829019+05:30
1187	\N	46	51	2025-07-25	2025-07-27	Checked-Out	19440.00	10.00	0.00	0.00	BankTransfer	3888.00	2025-10-06 23:33:18.829019+05:30
1188	\N	14	51	2025-07-29	2025-07-30	Checked-Out	18000.00	10.00	0.00	0.00	Cash	1800.00	2025-10-06 23:33:18.829019+05:30
1189	\N	25	51	2025-07-31	2025-08-04	Checked-Out	18000.00	10.00	0.00	0.00	Card	7200.00	2025-10-06 23:33:18.829019+05:30
1191	\N	51	51	2025-08-06	2025-08-10	Checked-Out	19800.00	10.00	0.00	0.00	Cash	7920.00	2025-10-06 23:33:18.829019+05:30
1193	\N	129	51	2025-08-17	2025-08-19	Checked-In	19800.00	10.00	0.00	0.00	BankTransfer	3960.00	2025-10-06 23:33:18.829019+05:30
1196	\N	92	51	2025-08-28	2025-08-31	Checked-Out	19800.00	10.00	0.00	0.00	BankTransfer	5940.00	2025-10-06 23:33:18.829019+05:30
1197	\N	143	51	2025-08-31	2025-09-04	Checked-Out	19800.00	10.00	0.00	0.00	Online	7920.00	2025-10-06 23:33:18.829019+05:30
1199	\N	96	51	2025-09-09	2025-09-12	Checked-Out	19800.00	10.00	0.00	0.00	Online	5940.00	2025-10-06 23:33:18.829019+05:30
1201	\N	25	51	2025-09-15	2025-09-17	Checked-Out	19800.00	10.00	0.00	0.00	Online	3960.00	2025-10-06 23:33:18.829019+05:30
1203	\N	91	51	2025-09-22	2025-09-27	Checked-Out	19800.00	10.00	0.00	0.00	Card	9900.00	2025-10-06 23:33:18.829019+05:30
1204	\N	57	51	2025-09-29	2025-10-03	Checked-In	19800.00	10.00	0.00	0.00	Online	7920.00	2025-10-06 23:33:18.829019+05:30
1205	\N	68	52	2025-07-01	2025-07-02	Checked-Out	18000.00	10.00	0.00	0.00	BankTransfer	1800.00	2025-10-06 23:33:18.829019+05:30
1206	\N	105	52	2025-07-04	2025-07-08	Checked-Out	19440.00	10.00	0.00	0.00	Cash	7776.00	2025-10-06 23:33:18.829019+05:30
1207	\N	40	52	2025-07-09	2025-07-13	Checked-Out	18000.00	10.00	0.00	0.00	Online	7200.00	2025-10-06 23:33:18.829019+05:30
1210	\N	58	52	2025-07-25	2025-07-28	Checked-In	19440.00	10.00	0.00	0.00	BankTransfer	5832.00	2025-10-06 23:33:18.829019+05:30
1214	\N	91	52	2025-08-07	2025-08-10	Checked-Out	19800.00	10.00	0.00	0.00	Online	5940.00	2025-10-06 23:33:18.829019+05:30
1217	\N	144	52	2025-08-17	2025-08-19	Checked-Out	19800.00	10.00	0.00	0.00	Cash	3960.00	2025-10-06 23:33:18.829019+05:30
1218	\N	37	52	2025-08-19	2025-08-23	Checked-Out	19800.00	10.00	0.00	0.00	BankTransfer	7920.00	2025-10-06 23:33:18.829019+05:30
1219	\N	96	52	2025-08-23	2025-08-25	Checked-Out	21384.00	10.00	0.00	0.00	Card	4276.80	2025-10-06 23:33:18.829019+05:30
1220	\N	144	52	2025-08-25	2025-08-26	Checked-In	19800.00	10.00	0.00	0.00	Online	1980.00	2025-10-06 23:33:18.829019+05:30
1149	\N	35	49	2025-08-24	2025-08-28	Checked-Out	19800.00	10.00	2067.87	0.00	Cash	7920.00	2025-10-06 23:33:18.829019+05:30
1161	\N	21	50	2025-07-17	2025-07-21	Checked-In	18000.00	10.00	2686.99	0.00	BankTransfer	7200.00	2025-10-06 23:33:18.829019+05:30
1194	\N	114	51	2025-08-20	2025-08-22	Checked-In	19800.00	10.00	2044.43	0.00	Cash	3960.00	2025-10-06 23:33:18.829019+05:30
1215	\N	86	52	2025-08-11	2025-08-13	Cancelled	19800.00	10.00	3517.32	0.00	BankTransfer	3960.00	2025-10-06 23:33:18.829019+05:30
1155	\N	70	49	2025-09-22	2025-09-27	Checked-Out	19800.00	10.00	2432.15	0.00	Online	9900.00	2025-10-06 23:33:18.829019+05:30
1141	\N	85	49	2025-07-28	2025-07-31	Checked-Out	18000.00	10.00	0.00	3827.56	Online	5400.00	2025-10-06 23:33:18.829019+05:30
1151	\N	10	49	2025-09-01	2025-09-04	Checked-Out	19800.00	10.00	1656.65	0.00	Cash	5940.00	2025-10-06 23:33:18.829019+05:30
1157	\N	140	50	2025-07-01	2025-07-05	Checked-Out	18000.00	10.00	2526.14	0.00	Cash	7200.00	2025-10-06 23:33:18.829019+05:30
1166	\N	10	50	2025-08-01	2025-08-05	Checked-In	21384.00	10.00	1306.01	0.00	Card	8553.60	2025-10-06 23:33:18.829019+05:30
1175	\N	96	50	2025-09-09	2025-09-12	Checked-In	19800.00	10.00	3572.19	0.00	BankTransfer	5940.00	2025-10-06 23:33:18.829019+05:30
1211	\N	140	52	2025-07-28	2025-07-30	Checked-Out	18000.00	10.00	2919.66	0.00	Online	3600.00	2025-10-06 23:33:18.829019+05:30
1158	\N	142	50	2025-07-06	2025-07-09	Checked-In	18000.00	10.00	2211.05	0.00	Online	5400.00	2025-10-06 23:33:18.829019+05:30
1170	\N	136	50	2025-08-19	2025-08-24	Checked-Out	19800.00	10.00	2432.15	0.00	Card	9900.00	2025-10-06 23:33:18.829019+05:30
1202	\N	47	51	2025-09-18	2025-09-21	Checked-Out	19800.00	10.00	2432.15	0.00	Online	5940.00	2025-10-06 23:33:18.829019+05:30
1209	\N	100	52	2025-07-19	2025-07-23	Checked-In	19440.00	10.00	2387.93	0.00	BankTransfer	7776.00	2025-10-06 23:33:18.829019+05:30
1195	\N	5	51	2025-08-23	2025-08-27	Checked-Out	21384.00	10.00	2626.72	0.00	BankTransfer	8553.60	2025-10-06 23:33:18.829019+05:30
1143	\N	52	49	2025-08-05	2025-08-07	Checked-Out	19800.00	10.00	0.00	2516.61	Cash	3960.00	2025-10-06 23:33:18.829019+05:30
1144	\N	66	49	2025-08-07	2025-08-09	Checked-Out	19800.00	10.00	0.00	3442.70	Cash	3960.00	2025-10-06 23:33:18.829019+05:30
1181	\N	22	51	2025-07-01	2025-07-03	Checked-In	18000.00	10.00	0.00	2860.50	Online	3600.00	2025-10-06 23:33:18.829019+05:30
1212	\N	4	52	2025-07-30	2025-08-01	Checked-Out	18000.00	10.00	0.00	3902.18	BankTransfer	3600.00	2025-10-06 23:33:18.829019+05:30
1216	\N	63	52	2025-08-14	2025-08-17	Checked-Out	19800.00	10.00	0.00	4384.10	Online	5940.00	2025-10-06 23:33:18.829019+05:30
1223	\N	26	52	2025-09-03	2025-09-07	Checked-In	19800.00	10.00	0.00	0.00	Cash	7920.00	2025-10-06 23:33:18.829019+05:30
1224	\N	54	52	2025-09-07	2025-09-11	Checked-Out	19800.00	10.00	0.00	0.00	Online	7920.00	2025-10-06 23:33:18.829019+05:30
1225	\N	121	52	2025-09-13	2025-09-17	Checked-In	21384.00	10.00	0.00	0.00	Online	8553.60	2025-10-06 23:33:18.829019+05:30
501	\N	20	22	2025-07-30	2025-08-01	Cancelled	40000.00	10.00	4855.34	0.00	Card	8000.00	2025-10-06 23:33:18.829019+05:30
1386	\N	45	59	2025-09-30	2025-10-01	Checked-In	13200.00	10.00	1621.43	0.00	Online	1320.00	2025-10-06 23:33:18.829019+05:30
1387	\N	81	60	2025-07-01	2025-07-04	Checked-In	12000.00	10.00	1015.33	0.00	Cash	3600.00	2025-10-06 23:33:18.829019+05:30
1408	\N	80	60	2025-09-24	2025-09-25	Checked-In	13200.00	10.00	2440.15	0.00	Card	1320.00	2025-10-06 23:33:18.829019+05:30
1	\N	1	1	2025-07-01	2025-07-05	Checked-Out	40000.00	10.00	4618.14	0.00	Cash	16000.00	2025-10-06 23:33:18.829019+05:30
156	\N	116	7	2025-08-16	2025-08-19	Checked-Out	28512.00	10.00	3560.26	0.00	Online	8553.60	2025-10-06 23:33:18.829019+05:30
198	\N	34	9	2025-08-01	2025-08-05	Checked-Out	21384.00	10.00	2146.77	0.00	Online	8553.60	2025-10-06 23:33:18.829019+05:30
234	\N	1	10	2025-09-18	2025-09-21	Checked-Out	19800.00	10.00	2432.15	0.00	Cash	5940.00	2025-10-06 23:33:18.829019+05:30
952	\N	89	41	2025-07-27	2025-07-28	Checked-Out	40000.00	10.00	6557.48	0.00	Cash	4000.00	2025-10-06 23:33:18.829019+05:30
1226	\N	92	52	2025-09-18	2025-09-19	Checked-Out	19800.00	10.00	0.00	0.00	Cash	1980.00	2025-10-06 23:33:18.829019+05:30
1227	\N	65	52	2025-09-19	2025-09-23	Checked-Out	21384.00	10.00	0.00	0.00	Cash	8553.60	2025-10-06 23:33:18.829019+05:30
1228	\N	65	52	2025-09-23	2025-09-27	Checked-Out	19800.00	10.00	0.00	0.00	Cash	7920.00	2025-10-06 23:33:18.829019+05:30
1230	\N	137	53	2025-07-01	2025-07-03	Checked-Out	18000.00	10.00	0.00	0.00	Cash	3600.00	2025-10-06 23:33:18.829019+05:30
1231	\N	106	53	2025-07-05	2025-07-08	Checked-Out	19440.00	10.00	0.00	0.00	BankTransfer	5832.00	2025-10-06 23:33:18.829019+05:30
1232	\N	88	53	2025-07-10	2025-07-13	Checked-Out	18000.00	10.00	0.00	0.00	Online	5400.00	2025-10-06 23:33:18.829019+05:30
1233	\N	144	53	2025-07-15	2025-07-19	Checked-Out	18000.00	10.00	0.00	0.00	Cash	7200.00	2025-10-06 23:33:18.829019+05:30
1234	\N	43	53	2025-07-20	2025-07-23	Checked-In	18000.00	10.00	0.00	0.00	Card	5400.00	2025-10-06 23:33:18.829019+05:30
1238	\N	108	53	2025-08-05	2025-08-09	Checked-In	19800.00	10.00	0.00	0.00	Online	7920.00	2025-10-06 23:33:18.829019+05:30
1240	\N	83	53	2025-08-17	2025-08-21	Checked-Out	19800.00	10.00	0.00	0.00	BankTransfer	7920.00	2025-10-06 23:33:18.829019+05:30
1242	\N	125	53	2025-08-25	2025-08-29	Checked-Out	19800.00	10.00	0.00	0.00	Card	7920.00	2025-10-06 23:33:18.829019+05:30
1247	\N	76	53	2025-09-19	2025-09-22	Checked-In	21384.00	10.00	0.00	0.00	Cash	6415.20	2025-10-06 23:33:18.829019+05:30
1248	\N	8	53	2025-09-24	2025-09-27	Checked-Out	19800.00	10.00	0.00	0.00	Online	5940.00	2025-10-06 23:33:18.829019+05:30
1253	\N	94	54	2025-07-12	2025-07-13	Checked-Out	19440.00	10.00	0.00	0.00	Cash	1944.00	2025-10-06 23:33:18.829019+05:30
1254	\N	142	54	2025-07-14	2025-07-18	Checked-In	18000.00	10.00	0.00	0.00	Cash	7200.00	2025-10-06 23:33:18.829019+05:30
1255	\N	136	54	2025-07-18	2025-07-22	Checked-Out	19440.00	10.00	0.00	0.00	Card	7776.00	2025-10-06 23:33:18.829019+05:30
1256	\N	50	54	2025-07-22	2025-07-25	Checked-Out	18000.00	10.00	0.00	0.00	Cash	5400.00	2025-10-06 23:33:18.829019+05:30
1257	\N	139	54	2025-07-26	2025-07-30	Checked-Out	19440.00	10.00	0.00	0.00	Online	7776.00	2025-10-06 23:33:18.829019+05:30
1258	\N	9	54	2025-07-31	2025-08-04	Checked-In	18000.00	10.00	0.00	0.00	BankTransfer	7200.00	2025-10-06 23:33:18.829019+05:30
1263	\N	10	54	2025-08-22	2025-08-23	Checked-Out	21384.00	10.00	0.00	0.00	BankTransfer	2138.40	2025-10-06 23:33:18.829019+05:30
1267	\N	126	54	2025-09-02	2025-09-06	Checked-In	19800.00	10.00	0.00	0.00	Cash	7920.00	2025-10-06 23:33:18.829019+05:30
1268	\N	57	54	2025-09-08	2025-09-12	Checked-Out	19800.00	10.00	0.00	0.00	Cash	7920.00	2025-10-06 23:33:18.829019+05:30
1270	\N	23	54	2025-09-16	2025-09-17	Checked-Out	19800.00	10.00	0.00	0.00	Online	1980.00	2025-10-06 23:33:18.829019+05:30
1272	\N	136	54	2025-09-20	2025-09-24	Checked-Out	21384.00	10.00	0.00	0.00	Card	8553.60	2025-10-06 23:33:18.829019+05:30
1274	\N	102	54	2025-09-30	2025-10-04	Checked-Out	19800.00	10.00	0.00	0.00	Cash	7920.00	2025-10-06 23:33:18.829019+05:30
1275	\N	105	55	2025-07-01	2025-07-03	Checked-Out	18000.00	10.00	0.00	0.00	BankTransfer	3600.00	2025-10-06 23:33:18.829019+05:30
1277	\N	102	55	2025-07-07	2025-07-11	Checked-Out	18000.00	10.00	0.00	0.00	BankTransfer	7200.00	2025-10-06 23:33:18.829019+05:30
1278	\N	19	55	2025-07-11	2025-07-15	Checked-Out	19440.00	10.00	0.00	0.00	Card	7776.00	2025-10-06 23:33:18.829019+05:30
1280	\N	12	55	2025-07-21	2025-07-25	Checked-Out	18000.00	10.00	0.00	0.00	Card	7200.00	2025-10-06 23:33:18.829019+05:30
1281	\N	52	55	2025-07-25	2025-07-26	Checked-Out	19440.00	10.00	0.00	0.00	Cash	1944.00	2025-10-06 23:33:18.829019+05:30
1283	\N	113	55	2025-08-01	2025-08-04	Checked-Out	21384.00	10.00	0.00	0.00	Cash	6415.20	2025-10-06 23:33:18.829019+05:30
1285	\N	88	55	2025-08-08	2025-08-12	Checked-Out	21384.00	10.00	0.00	0.00	Cash	8553.60	2025-10-06 23:33:18.829019+05:30
1286	\N	15	55	2025-08-14	2025-08-19	Checked-In	19800.00	10.00	0.00	0.00	Cash	9900.00	2025-10-06 23:33:18.829019+05:30
1288	\N	84	55	2025-08-23	2025-08-28	Checked-Out	21384.00	10.00	0.00	0.00	Cash	10692.00	2025-10-06 23:33:18.829019+05:30
1289	\N	132	55	2025-08-28	2025-08-31	Checked-Out	19800.00	10.00	0.00	0.00	Card	5940.00	2025-10-06 23:33:18.829019+05:30
1291	\N	45	55	2025-09-04	2025-09-05	Checked-In	19800.00	10.00	0.00	0.00	Cash	1980.00	2025-10-06 23:33:18.829019+05:30
1292	\N	58	55	2025-09-06	2025-09-08	Checked-Out	21384.00	10.00	0.00	0.00	BankTransfer	4276.80	2025-10-06 23:33:18.829019+05:30
1293	\N	131	55	2025-09-10	2025-09-14	Checked-Out	19800.00	10.00	0.00	0.00	Online	7920.00	2025-10-06 23:33:18.829019+05:30
1296	\N	63	55	2025-09-21	2025-09-23	Checked-In	19800.00	10.00	0.00	0.00	Online	3960.00	2025-10-06 23:33:18.829019+05:30
1297	\N	109	55	2025-09-25	2025-09-28	Checked-Out	19800.00	10.00	0.00	0.00	BankTransfer	5940.00	2025-10-06 23:33:18.829019+05:30
1298	\N	24	55	2025-09-29	2025-10-04	Checked-Out	19800.00	10.00	0.00	0.00	Cash	9900.00	2025-10-06 23:33:18.829019+05:30
1252	\N	93	54	2025-07-09	2025-07-10	Checked-Out	18000.00	10.00	3133.10	0.00	BankTransfer	1800.00	2025-10-06 23:33:18.829019+05:30
1260	\N	81	54	2025-08-11	2025-08-15	Checked-Out	19800.00	10.00	2197.31	0.00	Cash	7920.00	2025-10-06 23:33:18.829019+05:30
1237	\N	91	53	2025-08-02	2025-08-03	Checked-Out	21384.00	10.00	0.00	2228.93	Cash	2138.40	2025-10-06 23:33:18.829019+05:30
1265	\N	113	54	2025-08-26	2025-08-28	Checked-Out	19800.00	10.00	3035.50	0.00	Online	3960.00	2025-10-06 23:33:18.829019+05:30
1266	\N	96	54	2025-08-29	2025-09-01	Checked-Out	21384.00	10.00	3721.60	0.00	Cash	6415.20	2025-10-06 23:33:18.829019+05:30
1271	\N	80	54	2025-09-18	2025-09-19	Checked-Out	19800.00	10.00	3679.94	0.00	Online	1980.00	2025-10-06 23:33:18.829019+05:30
1222	\N	29	52	2025-08-30	2025-09-01	Checked-Out	21384.00	10.00	2626.72	0.00	Cash	4276.80	2025-10-06 23:33:18.829019+05:30
1245	\N	58	53	2025-09-08	2025-09-10	Checked-Out	19800.00	10.00	2432.15	0.00	Cash	3960.00	2025-10-06 23:33:18.829019+05:30
1284	\N	66	55	2025-08-04	2025-08-07	Checked-Out	19800.00	10.00	2432.15	0.00	Cash	5940.00	2025-10-06 23:33:18.829019+05:30
1251	\N	86	54	2025-07-04	2025-07-08	Checked-In	19440.00	10.00	2142.83	0.00	Online	7776.00	2025-10-06 23:33:18.829019+05:30
605	\N	36	26	2025-09-03	2025-09-04	Checked-Out	26400.00	10.00	3242.87	0.00	BankTransfer	2640.00	2025-10-06 23:33:18.829019+05:30
666	\N	55	29	2025-07-16	2025-07-18	Checked-In	18000.00	10.00	2211.05	0.00	Cash	3600.00	2025-10-06 23:33:18.829019+05:30
746	\N	101	32	2025-09-07	2025-09-11	Checked-Out	19800.00	10.00	2432.15	0.00	Card	7920.00	2025-10-06 23:33:18.829019+05:30
1295	\N	91	55	2025-09-19	2025-09-21	Checked-In	21384.00	10.00	2626.72	0.00	BankTransfer	4276.80	2025-10-06 23:33:18.829019+05:30
1261	\N	58	54	2025-08-17	2025-08-18	Checked-Out	19800.00	10.00	2432.15	0.00	Cash	1980.00	2025-10-06 23:33:18.829019+05:30
1239	\N	138	53	2025-08-11	2025-08-16	Cancelled	19800.00	10.00	0.00	0.00	Card	9900.00	2025-10-06 23:33:18.829019+05:30
1244	\N	82	53	2025-09-05	2025-09-07	Cancelled	21384.00	10.00	0.00	0.00	Online	4276.80	2025-10-06 23:33:18.829019+05:30
1249	\N	116	53	2025-09-27	2025-10-01	Cancelled	21384.00	10.00	0.00	0.00	Cash	8553.60	2025-10-06 23:33:18.829019+05:30
1250	\N	150	54	2025-07-01	2025-07-03	Cancelled	18000.00	10.00	0.00	0.00	Online	3600.00	2025-10-06 23:33:18.829019+05:30
1246	\N	81	53	2025-09-12	2025-09-17	Cancelled	21384.00	10.00	1086.57	0.00	Cash	10692.00	2025-10-06 23:33:18.829019+05:30
1269	\N	82	54	2025-09-13	2025-09-15	Checked-In	21384.00	10.00	0.00	3109.19	Online	4276.80	2025-10-06 23:33:18.829019+05:30
1273	\N	31	54	2025-09-25	2025-09-29	Checked-Out	19800.00	10.00	0.00	2887.03	Cash	7920.00	2025-10-06 23:33:18.829019+05:30
1276	\N	55	55	2025-07-05	2025-07-07	Checked-Out	19440.00	10.00	0.00	4267.62	Online	3888.00	2025-10-06 23:33:18.829019+05:30
1302	\N	22	56	2025-07-10	2025-07-14	Checked-Out	12000.00	10.00	0.00	1994.07	BankTransfer	4800.00	2025-10-06 23:33:18.829019+05:30
1241	\N	78	53	2025-08-23	2025-08-25	Checked-Out	21384.00	10.00	2626.72	2875.72	Online	4276.80	2025-10-06 23:33:18.829019+05:30
1304	\N	90	56	2025-07-19	2025-07-20	Checked-Out	12960.00	10.00	0.00	0.00	Online	1296.00	2025-10-06 23:33:18.829019+05:30
1307	\N	129	56	2025-07-31	2025-08-02	Checked-Out	12000.00	10.00	0.00	0.00	Card	2400.00	2025-10-06 23:33:18.829019+05:30
1309	\N	68	56	2025-08-06	2025-08-09	Checked-In	13200.00	10.00	0.00	0.00	Card	3960.00	2025-10-06 23:33:18.829019+05:30
1310	\N	125	56	2025-08-10	2025-08-15	Checked-Out	13200.00	10.00	0.00	0.00	Cash	6600.00	2025-10-06 23:33:18.829019+05:30
1311	\N	82	56	2025-08-16	2025-08-20	Checked-Out	14256.00	10.00	0.00	0.00	BankTransfer	5702.40	2025-10-06 23:33:18.829019+05:30
1312	\N	39	56	2025-08-21	2025-08-26	Checked-Out	13200.00	10.00	0.00	0.00	Cash	6600.00	2025-10-06 23:33:18.829019+05:30
1313	\N	63	56	2025-08-28	2025-09-01	Checked-Out	13200.00	10.00	0.00	0.00	Cash	5280.00	2025-10-06 23:33:18.829019+05:30
1314	\N	80	56	2025-09-03	2025-09-07	Checked-Out	13200.00	10.00	0.00	0.00	Online	5280.00	2025-10-06 23:33:18.829019+05:30
1317	\N	123	56	2025-09-16	2025-09-21	Checked-Out	13200.00	10.00	0.00	0.00	Online	6600.00	2025-10-06 23:33:18.829019+05:30
1318	\N	16	56	2025-09-21	2025-09-24	Checked-Out	13200.00	10.00	0.00	0.00	Online	3960.00	2025-10-06 23:33:18.829019+05:30
1319	\N	58	56	2025-09-26	2025-09-30	Checked-Out	14256.00	10.00	0.00	0.00	Card	5702.40	2025-10-06 23:33:18.829019+05:30
1321	\N	89	57	2025-07-01	2025-07-05	Checked-In	12000.00	10.00	0.00	0.00	Online	4800.00	2025-10-06 23:33:18.829019+05:30
1322	\N	112	57	2025-07-07	2025-07-10	Checked-Out	12000.00	10.00	0.00	0.00	Online	3600.00	2025-10-06 23:33:18.829019+05:30
1323	\N	98	57	2025-07-11	2025-07-13	Checked-Out	12960.00	10.00	0.00	0.00	Online	2592.00	2025-10-06 23:33:18.829019+05:30
1325	\N	19	57	2025-07-22	2025-07-26	Checked-Out	12000.00	10.00	0.00	0.00	Cash	4800.00	2025-10-06 23:33:18.829019+05:30
1326	\N	91	57	2025-07-26	2025-07-30	Checked-In	12960.00	10.00	0.00	0.00	Card	5184.00	2025-10-06 23:33:18.829019+05:30
1328	\N	21	57	2025-08-02	2025-08-06	Checked-In	14256.00	10.00	0.00	0.00	Card	5702.40	2025-10-06 23:33:18.829019+05:30
1329	\N	133	57	2025-08-07	2025-08-09	Checked-Out	13200.00	10.00	0.00	0.00	Online	2640.00	2025-10-06 23:33:18.829019+05:30
1330	\N	22	57	2025-08-10	2025-08-15	Checked-In	13200.00	10.00	0.00	0.00	Card	6600.00	2025-10-06 23:33:18.829019+05:30
1332	\N	142	57	2025-08-20	2025-08-24	Checked-Out	13200.00	10.00	0.00	0.00	Cash	5280.00	2025-10-06 23:33:18.829019+05:30
1335	\N	79	57	2025-08-31	2025-09-02	Checked-Out	13200.00	10.00	0.00	0.00	Online	2640.00	2025-10-06 23:33:18.829019+05:30
1337	\N	145	57	2025-09-08	2025-09-13	Checked-Out	13200.00	10.00	0.00	0.00	BankTransfer	6600.00	2025-10-06 23:33:18.829019+05:30
1338	\N	80	57	2025-09-15	2025-09-18	Checked-Out	13200.00	10.00	0.00	0.00	Cash	3960.00	2025-10-06 23:33:18.829019+05:30
1341	\N	80	57	2025-09-26	2025-09-28	Checked-In	14256.00	10.00	0.00	0.00	Online	2851.20	2025-10-06 23:33:18.829019+05:30
1342	\N	150	57	2025-09-30	2025-10-04	Checked-Out	13200.00	10.00	0.00	0.00	BankTransfer	5280.00	2025-10-06 23:33:18.829019+05:30
1343	\N	99	58	2025-07-01	2025-07-05	Checked-Out	12000.00	10.00	0.00	0.00	Cash	4800.00	2025-10-06 23:33:18.829019+05:30
1344	\N	50	58	2025-07-05	2025-07-07	Checked-Out	12960.00	10.00	0.00	0.00	Card	2592.00	2025-10-06 23:33:18.829019+05:30
1345	\N	31	58	2025-07-08	2025-07-13	Checked-Out	12000.00	10.00	0.00	0.00	BankTransfer	6000.00	2025-10-06 23:33:18.829019+05:30
1348	\N	101	58	2025-07-20	2025-07-23	Checked-Out	12000.00	10.00	0.00	0.00	Cash	3600.00	2025-10-06 23:33:18.829019+05:30
1351	\N	107	58	2025-08-02	2025-08-04	Checked-Out	14256.00	10.00	0.00	0.00	Cash	2851.20	2025-10-06 23:33:18.829019+05:30
1356	\N	39	58	2025-08-23	2025-08-27	Checked-Out	14256.00	10.00	0.00	0.00	Online	5702.40	2025-10-06 23:33:18.829019+05:30
1357	\N	54	58	2025-08-27	2025-09-01	Checked-Out	13200.00	10.00	0.00	0.00	Card	6600.00	2025-10-06 23:33:18.829019+05:30
1362	\N	102	58	2025-09-22	2025-09-24	Checked-Out	13200.00	10.00	0.00	0.00	Online	2640.00	2025-10-06 23:33:18.829019+05:30
1363	\N	28	58	2025-09-25	2025-09-29	Checked-Out	13200.00	10.00	0.00	0.00	Cash	5280.00	2025-10-06 23:33:18.829019+05:30
1364	\N	101	58	2025-09-29	2025-10-04	Checked-In	13200.00	10.00	0.00	0.00	Cash	6600.00	2025-10-06 23:33:18.829019+05:30
1365	\N	144	59	2025-07-01	2025-07-03	Checked-Out	12000.00	10.00	0.00	0.00	Cash	2400.00	2025-10-06 23:33:18.829019+05:30
1367	\N	36	59	2025-07-11	2025-07-13	Checked-Out	12960.00	10.00	0.00	0.00	Card	2592.00	2025-10-06 23:33:18.829019+05:30
1368	\N	32	59	2025-07-13	2025-07-16	Checked-Out	12000.00	10.00	0.00	0.00	Online	3600.00	2025-10-06 23:33:18.829019+05:30
1370	\N	66	59	2025-07-22	2025-07-25	Checked-Out	12000.00	10.00	0.00	0.00	Online	3600.00	2025-10-06 23:33:18.829019+05:30
1371	\N	100	59	2025-07-27	2025-07-30	Checked-In	12000.00	10.00	0.00	0.00	Online	3600.00	2025-10-06 23:33:18.829019+05:30
1374	\N	126	59	2025-08-06	2025-08-08	Checked-In	13200.00	10.00	0.00	0.00	Cash	2640.00	2025-10-06 23:33:18.829019+05:30
1376	\N	116	59	2025-08-15	2025-08-17	Checked-Out	14256.00	10.00	0.00	0.00	Card	2851.20	2025-10-06 23:33:18.829019+05:30
1378	\N	37	59	2025-08-22	2025-08-25	Checked-Out	14256.00	10.00	0.00	0.00	Online	4276.80	2025-10-06 23:33:18.829019+05:30
1379	\N	147	59	2025-08-26	2025-08-30	Checked-Out	13200.00	10.00	0.00	0.00	Online	5280.00	2025-10-06 23:33:18.829019+05:30
1380	\N	56	59	2025-09-01	2025-09-04	Checked-Out	13200.00	10.00	0.00	0.00	Online	3960.00	2025-10-06 23:33:18.829019+05:30
1381	\N	16	59	2025-09-06	2025-09-10	Checked-Out	14256.00	10.00	0.00	0.00	Online	5702.40	2025-10-06 23:33:18.829019+05:30
1383	\N	50	59	2025-09-14	2025-09-19	Checked-In	13200.00	10.00	0.00	0.00	BankTransfer	6600.00	2025-10-06 23:33:18.829019+05:30
1333	\N	50	57	2025-08-24	2025-08-27	Checked-Out	13200.00	10.00	1052.17	0.00	Card	3960.00	2025-10-06 23:33:18.829019+05:30
1449	\N	1	5	2025-11-10	2025-11-12	Checked-In	20000.00	0.00	0.00	0.00	\N	10000.00	2025-10-07 19:31:12.65907+05:30
1425	\N	125	47	2025-10-08	2025-10-12	Booked	24000.00	10.00	2948.06	0.00	Card	9600.00	2025-10-06 23:33:18.829019+05:30
284	\N	29	12	2025-09-25	2025-09-29	Checked-Out	19800.00	10.00	3755.52	0.00	Online	7920.00	2025-10-06 23:33:18.829019+05:30
606	\N	48	26	2025-09-05	2025-09-08	Checked-Out	28512.00	10.00	2340.32	0.00	Cash	8553.60	2025-10-06 23:33:18.829019+05:30
124	\N	90	6	2025-07-30	2025-07-31	Checked-Out	24000.00	10.00	2948.06	0.00	Online	2400.00	2025-10-06 23:33:18.829019+05:30
128	\N	128	6	2025-08-08	2025-08-12	Checked-Out	28512.00	10.00	3502.30	0.00	Cash	11404.80	2025-10-06 23:33:18.829019+05:30
136	\N	111	6	2025-09-07	2025-09-09	Checked-Out	26400.00	10.00	3242.87	0.00	BankTransfer	5280.00	2025-10-06 23:33:18.829019+05:30
325	\N	7	14	2025-09-20	2025-09-25	Checked-Out	21384.00	10.00	2626.72	0.00	Online	10692.00	2025-10-06 23:33:18.829019+05:30
814	\N	10	35	2025-08-18	2025-08-20	Checked-Out	19800.00	10.00	2432.15	0.00	Online	3960.00	2025-10-06 23:33:18.829019+05:30
1120	\N	72	48	2025-08-11	2025-08-12	Checked-Out	26400.00	10.00	3242.87	0.00	Card	2640.00	2025-10-06 23:33:18.829019+05:30
1294	\N	121	55	2025-09-15	2025-09-18	Cancelled	19800.00	10.00	3905.19	0.00	Cash	5940.00	2025-10-06 23:33:18.829019+05:30
326	\N	42	14	2025-09-25	2025-09-29	Cancelled	19800.00	10.00	2012.20	0.00	Cash	7920.00	2025-10-06 23:33:18.829019+05:30
1118	\N	113	48	2025-08-03	2025-08-08	Cancelled	26400.00	10.00	3277.92	0.00	Online	13200.00	2025-10-06 23:33:18.829019+05:30
1125	\N	7	48	2025-08-27	2025-08-29	Cancelled	26400.00	10.00	3642.93	0.00	Online	5280.00	2025-10-06 23:33:18.829019+05:30
1377	\N	117	59	2025-08-18	2025-08-21	Cancelled	13200.00	10.00	1229.24	0.00	Online	3960.00	2025-10-06 23:33:18.829019+05:30
1279	\N	3	55	2025-07-16	2025-07-19	Checked-Out	18000.00	10.00	3120.70	2418.27	Online	5400.00	2025-10-06 23:33:18.829019+05:30
301	\N	109	13	2025-09-03	2025-09-05	Checked-In	19800.00	10.00	3361.08	2814.18	BankTransfer	3960.00	2025-10-06 23:33:18.829019+05:30
725	\N	70	31	2025-09-19	2025-09-24	Checked-Out	21384.00	10.00	2073.10	2842.46	Card	10692.00	2025-10-06 23:33:18.829019+05:30
1016	\N	143	44	2025-07-21	2025-07-26	Checked-Out	24000.00	10.00	2948.06	4324.16	Online	12000.00	2025-10-06 23:33:18.829019+05:30
1128	\N	137	48	2025-09-08	2025-09-10	Checked-Out	26400.00	10.00	3242.87	0.00	Cash	5280.00	2025-10-06 23:33:18.829019+05:30
1299	\N	146	56	2025-07-01	2025-07-04	Checked-Out	12000.00	10.00	1474.03	0.00	Online	3600.00	2025-10-06 23:33:18.829019+05:30
565	\N	36	24	2025-09-19	2025-09-24	Checked-Out	28512.00	10.00	3502.30	0.00	BankTransfer	14256.00	2025-10-06 23:33:18.829019+05:30
237	\N	42	10	2025-09-29	2025-10-03	Checked-Out	19800.00	10.00	2432.15	0.00	Cash	7920.00	2025-10-06 23:33:18.829019+05:30
243	\N	71	11	2025-07-23	2025-07-26	Checked-Out	18000.00	10.00	2211.05	0.00	Card	5400.00	2025-10-06 23:33:18.829019+05:30
848	\N	72	36	2025-09-20	2025-09-22	Cancelled	14256.00	10.00	1703.31	0.00	Online	2851.20	2025-10-06 23:33:18.829019+05:30
104	\N	57	5	2025-08-10	2025-08-15	Cancelled	26400.00	10.00	3242.87	0.00	Online	13200.00	2025-10-06 23:33:18.829019+05:30
189	\N	46	8	2025-09-27	2025-09-29	Checked-Out	28512.00	10.00	3502.30	6346.62	Online	5702.40	2025-10-06 23:33:18.829019+05:30
233	\N	82	10	2025-09-13	2025-09-16	Checked-Out	21384.00	10.00	2626.72	6266.21	Cash	6415.20	2025-10-06 23:33:18.829019+05:30
805	\N	78	35	2025-07-15	2025-07-18	Checked-In	18000.00	10.00	0.00	2116.82	BankTransfer	5400.00	2025-10-06 23:33:18.829019+05:30
811	\N	96	35	2025-08-06	2025-08-07	Checked-Out	19800.00	10.00	0.00	3780.20	Cash	1980.00	2025-10-06 23:33:18.829019+05:30
742	\N	5	32	2025-08-24	2025-08-26	Checked-Out	19800.00	10.00	3434.93	4267.08	Card	3960.00	2025-10-06 23:33:18.829019+05:30
734	\N	145	32	2025-07-25	2025-07-28	Checked-Out	19440.00	10.00	2387.93	5651.67	Cash	5832.00	2025-10-06 23:33:18.829019+05:30
1350	\N	82	58	2025-07-29	2025-08-02	Checked-Out	12000.00	10.00	0.00	1477.79	Online	4800.00	2025-10-06 23:33:18.829019+05:30
1336	\N	125	57	2025-09-03	2025-09-07	Checked-Out	13200.00	10.00	2243.80	0.00	Card	5280.00	2025-10-06 23:33:18.829019+05:30
1354	\N	19	58	2025-08-14	2025-08-15	Checked-Out	13200.00	10.00	2293.53	0.00	BankTransfer	1320.00	2025-10-06 23:33:18.829019+05:30
1358	\N	13	58	2025-09-03	2025-09-08	Checked-Out	13200.00	10.00	1747.78	0.00	Online	6600.00	2025-10-06 23:33:18.829019+05:30
1361	\N	139	58	2025-09-17	2025-09-21	Checked-Out	13200.00	10.00	1304.07	0.00	Cash	5280.00	2025-10-06 23:33:18.829019+05:30
1340	\N	134	57	2025-09-21	2025-09-25	Checked-Out	13200.00	10.00	1428.55	0.00	Cash	5280.00	2025-10-06 23:33:18.829019+05:30
1346	\N	57	58	2025-07-14	2025-07-17	Checked-Out	12000.00	10.00	1043.39	0.00	Online	3600.00	2025-10-06 23:33:18.829019+05:30
1331	\N	147	57	2025-08-15	2025-08-19	Cancelled	14256.00	10.00	0.00	0.00	Cash	5702.40	2025-10-06 23:33:18.829019+05:30
1359	\N	132	58	2025-09-10	2025-09-14	Cancelled	13200.00	10.00	0.00	0.00	Card	5280.00	2025-10-06 23:33:18.829019+05:30
1334	\N	64	57	2025-08-29	2025-08-31	Cancelled	14256.00	10.00	1554.23	0.00	Cash	2851.20	2025-10-06 23:33:18.829019+05:30
1347	\N	24	58	2025-07-17	2025-07-19	Cancelled	12000.00	10.00	1474.03	0.00	Online	2400.00	2025-10-06 23:33:18.829019+05:30
1360	\N	126	58	2025-09-14	2025-09-16	Checked-Out	13200.00	10.00	814.52	3833.99	Card	2640.00	2025-10-06 23:33:18.829019+05:30
1384	\N	7	59	2025-09-21	2025-09-25	Checked-Out	13200.00	10.00	0.00	0.00	Card	5280.00	2025-10-06 23:33:18.829019+05:30
1389	\N	100	60	2025-07-10	2025-07-12	Checked-Out	12000.00	10.00	0.00	0.00	Card	2400.00	2025-10-06 23:33:18.829019+05:30
1391	\N	72	60	2025-07-18	2025-07-20	Checked-Out	12960.00	10.00	0.00	0.00	Cash	2592.00	2025-10-06 23:33:18.829019+05:30
1393	\N	129	60	2025-07-27	2025-07-31	Checked-In	12000.00	10.00	0.00	0.00	Card	4800.00	2025-10-06 23:33:18.829019+05:30
1394	\N	14	60	2025-08-01	2025-08-02	Checked-In	14256.00	10.00	0.00	0.00	Cash	1425.60	2025-10-06 23:33:18.829019+05:30
1395	\N	8	60	2025-08-02	2025-08-06	Checked-Out	14256.00	10.00	0.00	0.00	BankTransfer	5702.40	2025-10-06 23:33:18.829019+05:30
1396	\N	7	60	2025-08-07	2025-08-10	Checked-Out	13200.00	10.00	0.00	0.00	Online	3960.00	2025-10-06 23:33:18.829019+05:30
1397	\N	32	60	2025-08-12	2025-08-14	Checked-Out	13200.00	10.00	0.00	0.00	Cash	2640.00	2025-10-06 23:33:18.829019+05:30
1399	\N	148	60	2025-08-19	2025-08-23	Checked-Out	13200.00	10.00	0.00	0.00	Online	5280.00	2025-10-06 23:33:18.829019+05:30
1400	\N	53	60	2025-08-24	2025-08-26	Checked-Out	13200.00	10.00	0.00	0.00	Cash	2640.00	2025-10-06 23:33:18.829019+05:30
1401	\N	128	60	2025-08-28	2025-08-30	Checked-Out	13200.00	10.00	0.00	0.00	Card	2640.00	2025-10-06 23:33:18.829019+05:30
1402	\N	73	60	2025-08-31	2025-09-04	Checked-In	13200.00	10.00	0.00	0.00	Cash	5280.00	2025-10-06 23:33:18.829019+05:30
1404	\N	69	60	2025-09-07	2025-09-12	Checked-Out	13200.00	10.00	0.00	0.00	Cash	6600.00	2025-10-06 23:33:18.829019+05:30
1407	\N	34	60	2025-09-21	2025-09-22	Checked-Out	13200.00	10.00	0.00	0.00	Card	1320.00	2025-10-06 23:33:18.829019+05:30
1409	\N	15	60	2025-09-26	2025-09-29	Checked-Out	14256.00	10.00	0.00	0.00	BankTransfer	4276.80	2025-10-06 23:33:18.829019+05:30
1410	\N	38	60	2025-09-30	2025-10-01	Checked-Out	13200.00	10.00	0.00	0.00	BankTransfer	1320.00	2025-10-06 23:33:18.829019+05:30
15	\N	75	1	2025-08-31	2025-09-04	Checked-Out	44000.00	10.00	3411.77	0.00	Cash	17600.00	2025-10-06 23:33:18.829019+05:30
20	\N	58	1	2025-09-23	2025-09-26	Checked-Out	44000.00	10.00	3795.87	0.00	Cash	13200.00	2025-10-06 23:33:18.829019+05:30
52	\N	86	3	2025-07-20	2025-07-22	Checked-In	40000.00	10.00	3521.68	0.00	Cash	8000.00	2025-10-06 23:33:18.829019+05:30
66	\N	38	3	2025-09-15	2025-09-19	Checked-Out	44000.00	10.00	7126.80	0.00	Card	17600.00	2025-10-06 23:33:18.829019+05:30
76	\N	20	4	2025-07-18	2025-07-20	Checked-Out	25920.00	10.00	2940.11	0.00	Card	5184.00	2025-10-06 23:33:18.829019+05:30
78	\N	48	4	2025-07-25	2025-07-29	Checked-Out	25920.00	10.00	4684.90	0.00	Cash	10368.00	2025-10-06 23:33:18.829019+05:30
83	\N	106	4	2025-08-17	2025-08-19	Checked-In	26400.00	10.00	2039.90	0.00	BankTransfer	5280.00	2025-10-06 23:33:18.829019+05:30
121	\N	44	6	2025-07-14	2025-07-16	Checked-Out	24000.00	10.00	3244.33	0.00	BankTransfer	4800.00	2025-10-06 23:33:18.829019+05:30
126	\N	115	6	2025-08-02	2025-08-05	Checked-Out	28512.00	10.00	1772.79	0.00	BankTransfer	8553.60	2025-10-06 23:33:18.829019+05:30
127	\N	40	6	2025-08-05	2025-08-08	Checked-Out	26400.00	10.00	3581.45	0.00	Cash	7920.00	2025-10-06 23:33:18.829019+05:30
129	\N	118	6	2025-08-14	2025-08-17	Checked-Out	26400.00	10.00	4855.41	0.00	Cash	7920.00	2025-10-06 23:33:18.829019+05:30
138	\N	139	6	2025-09-12	2025-09-13	Checked-Out	28512.00	10.00	1792.05	0.00	Online	2851.20	2025-10-06 23:33:18.829019+05:30
163	\N	100	7	2025-09-18	2025-09-22	Checked-Out	26400.00	10.00	1395.52	0.00	Online	10560.00	2025-10-06 23:33:18.829019+05:30
185	\N	141	8	2025-09-09	2025-09-14	Checked-Out	26400.00	10.00	2548.44	0.00	Online	13200.00	2025-10-06 23:33:18.829019+05:30
217	\N	24	10	2025-07-26	2025-07-30	Checked-Out	19440.00	10.00	3052.92	0.00	Online	7776.00	2025-10-06 23:33:18.829019+05:30
232	\N	1	10	2025-09-11	2025-09-12	Checked-Out	19800.00	10.00	1105.69	0.00	Cash	1980.00	2025-10-06 23:33:18.829019+05:30
238	\N	93	11	2025-07-01	2025-07-06	Checked-Out	18000.00	10.00	2130.36	0.00	Online	9000.00	2025-10-06 23:33:18.829019+05:30
239	\N	83	11	2025-07-06	2025-07-07	Checked-Out	18000.00	10.00	1593.77	0.00	Cash	1800.00	2025-10-06 23:33:18.829019+05:30
254	\N	20	11	2025-08-30	2025-09-03	Checked-Out	21384.00	10.00	2499.81	0.00	Online	8553.60	2025-10-06 23:33:18.829019+05:30
270	\N	32	12	2025-08-02	2025-08-05	Checked-Out	21384.00	10.00	1862.47	0.00	Online	6415.20	2025-10-06 23:33:18.829019+05:30
294	\N	86	13	2025-08-04	2025-08-08	Checked-Out	19800.00	10.00	1267.24	0.00	Online	7920.00	2025-10-06 23:33:18.829019+05:30
327	\N	65	14	2025-09-29	2025-10-03	Checked-Out	19800.00	10.00	3160.27	0.00	Online	7920.00	2025-10-06 23:33:18.829019+05:30
361	\N	117	16	2025-07-29	2025-07-31	Checked-Out	12000.00	10.00	1066.28	0.00	Online	2400.00	2025-10-06 23:33:18.829019+05:30
365	\N	81	16	2025-08-12	2025-08-14	Checked-Out	13200.00	10.00	2058.00	0.00	BankTransfer	2640.00	2025-10-06 23:33:18.829019+05:30
405	\N	105	18	2025-07-14	2025-07-19	Checked-Out	12000.00	10.00	2319.10	0.00	Card	6000.00	2025-10-06 23:33:18.829019+05:30
435	\N	31	19	2025-08-09	2025-08-12	Checked-Out	14256.00	10.00	1850.88	0.00	BankTransfer	4276.80	2025-10-06 23:33:18.829019+05:30
438	\N	45	19	2025-08-18	2025-08-21	Checked-Out	13200.00	10.00	1884.39	0.00	Card	3960.00	2025-10-06 23:33:18.829019+05:30
462	\N	59	20	2025-08-20	2025-08-23	Checked-In	13200.00	10.00	1163.33	0.00	Online	3960.00	2025-10-06 23:33:18.829019+05:30
1388	\N	11	60	2025-07-05	2025-07-09	Checked-Out	12960.00	10.00	1855.27	0.00	Cash	5184.00	2025-10-06 23:33:18.829019+05:30
339	\N	66	15	2025-08-10	2025-08-11	Cancelled	19800.00	10.00	1364.69	0.00	Online	1980.00	2025-10-06 23:33:18.829019+05:30
1392	\N	102	60	2025-07-21	2025-07-26	Checked-Out	12000.00	10.00	1474.03	0.00	BankTransfer	6000.00	2025-10-06 23:33:18.829019+05:30
50	\N	141	3	2025-07-12	2025-07-15	Checked-In	43200.00	10.00	5306.51	0.00	Card	12960.00	2025-10-06 23:33:18.829019+05:30
312	\N	115	14	2025-07-21	2025-07-26	Checked-In	18000.00	10.00	1371.61	3634.37	Cash	9000.00	2025-10-06 23:33:18.829019+05:30
225	\N	120	10	2025-08-20	2025-08-22	Checked-In	19800.00	10.00	2432.15	4017.04	Online	3960.00	2025-10-06 23:33:18.829019+05:30
488	\N	148	21	2025-09-09	2025-09-13	Checked-Out	44000.00	10.00	3990.92	0.00	BankTransfer	17600.00	2025-10-06 23:33:18.829019+05:30
495	\N	124	22	2025-07-04	2025-07-09	Checked-In	43200.00	10.00	4830.19	0.00	BankTransfer	21600.00	2025-10-06 23:33:18.829019+05:30
506	\N	32	22	2025-08-20	2025-08-24	Checked-Out	44000.00	10.00	7944.81	0.00	Card	17600.00	2025-10-06 23:33:18.829019+05:30
517	\N	113	22	2025-09-30	2025-10-04	Checked-Out	44000.00	10.00	2861.81	0.00	Online	17600.00	2025-10-06 23:33:18.829019+05:30
527	\N	18	23	2025-08-02	2025-08-06	Checked-Out	47520.00	10.00	6118.21	0.00	Online	19008.00	2025-10-06 23:33:18.829019+05:30
548	\N	49	24	2025-07-17	2025-07-18	Checked-Out	24000.00	10.00	3327.15	0.00	BankTransfer	2400.00	2025-10-06 23:33:18.829019+05:30
549	\N	69	24	2025-07-19	2025-07-20	Checked-Out	25920.00	10.00	2894.49	0.00	BankTransfer	2592.00	2025-10-06 23:33:18.829019+05:30
560	\N	18	24	2025-08-30	2025-08-31	Checked-Out	28512.00	10.00	2753.80	0.00	Cash	2851.20	2025-10-06 23:33:18.829019+05:30
574	\N	92	25	2025-07-24	2025-07-28	Checked-Out	24000.00	10.00	3375.05	0.00	Card	9600.00	2025-10-06 23:33:18.829019+05:30
587	\N	57	25	2025-09-17	2025-09-20	Checked-Out	26400.00	10.00	5277.77	0.00	Cash	7920.00	2025-10-06 23:33:18.829019+05:30
595	\N	146	26	2025-07-16	2025-07-21	Checked-Out	24000.00	10.00	2014.17	0.00	Cash	12000.00	2025-10-06 23:33:18.829019+05:30
604	\N	150	26	2025-08-31	2025-09-02	Checked-Out	26400.00	10.00	1501.22	0.00	Cash	5280.00	2025-10-06 23:33:18.829019+05:30
615	\N	130	27	2025-07-08	2025-07-10	Checked-In	24000.00	10.00	4443.87	0.00	Cash	4800.00	2025-10-06 23:33:18.829019+05:30
644	\N	4	28	2025-08-01	2025-08-02	Checked-In	28512.00	10.00	2080.68	0.00	Online	2851.20	2025-10-06 23:33:18.829019+05:30
726	\N	85	31	2025-09-26	2025-09-30	Checked-In	21384.00	10.00	3909.41	0.00	Online	8553.60	2025-10-06 23:33:18.829019+05:30
730	\N	121	32	2025-07-13	2025-07-14	Checked-Out	18000.00	10.00	3008.12	0.00	Card	1800.00	2025-10-06 23:33:18.829019+05:30
732	\N	35	32	2025-07-19	2025-07-20	Checked-In	19440.00	10.00	3653.59	0.00	Card	1944.00	2025-10-06 23:33:18.829019+05:30
733	\N	141	32	2025-07-21	2025-07-23	Checked-Out	18000.00	10.00	2980.77	0.00	Card	3600.00	2025-10-06 23:33:18.829019+05:30
758	\N	133	33	2025-08-04	2025-08-06	Checked-Out	19800.00	10.00	1617.87	0.00	Online	3960.00	2025-10-06 23:33:18.829019+05:30
770	\N	60	33	2025-09-21	2025-09-26	Checked-Out	19800.00	10.00	2759.36	0.00	Cash	9900.00	2025-10-06 23:33:18.829019+05:30
812	\N	119	35	2025-08-09	2025-08-12	Checked-Out	21384.00	10.00	2772.59	0.00	Cash	6415.20	2025-10-06 23:33:18.829019+05:30
859	\N	1	37	2025-07-29	2025-08-03	Checked-Out	12000.00	10.00	1253.52	0.00	Card	6000.00	2025-10-06 23:33:18.829019+05:30
891	\N	138	38	2025-08-22	2025-08-24	Checked-Out	14256.00	10.00	2760.80	0.00	Online	2851.20	2025-10-06 23:33:18.829019+05:30
896	\N	1	38	2025-09-12	2025-09-15	Checked-Out	14256.00	10.00	2158.01	0.00	Cash	4276.80	2025-10-06 23:33:18.829019+05:30
929	\N	97	40	2025-07-27	2025-07-30	Checked-Out	12000.00	10.00	2323.12	0.00	Cash	3600.00	2025-10-06 23:33:18.829019+05:30
932	\N	27	40	2025-08-08	2025-08-09	Checked-In	14256.00	10.00	1526.52	0.00	Online	1425.60	2025-10-06 23:33:18.829019+05:30
940	\N	147	40	2025-09-11	2025-09-13	Checked-Out	13200.00	10.00	1366.39	0.00	Cash	2640.00	2025-10-06 23:33:18.829019+05:30
973	\N	144	42	2025-07-22	2025-07-24	Checked-Out	40000.00	10.00	4410.37	0.00	BankTransfer	8000.00	2025-10-06 23:33:18.829019+05:30
974	\N	48	42	2025-07-25	2025-07-29	Checked-Out	43200.00	10.00	2857.03	0.00	Online	17280.00	2025-10-06 23:33:18.829019+05:30
984	\N	150	42	2025-09-10	2025-09-15	Checked-Out	44000.00	10.00	6772.85	0.00	Online	22000.00	2025-10-06 23:33:18.829019+05:30
996	\N	145	43	2025-07-27	2025-07-31	Checked-Out	40000.00	10.00	7685.29	0.00	Online	16000.00	2025-10-06 23:33:18.829019+05:30
1005	\N	25	43	2025-09-05	2025-09-10	Checked-Out	47520.00	10.00	3841.77	0.00	Cash	23760.00	2025-10-06 23:33:18.829019+05:30
1006	\N	132	43	2025-09-10	2025-09-12	Checked-Out	44000.00	10.00	6051.20	0.00	Online	8800.00	2025-10-06 23:33:18.829019+05:30
1025	\N	92	44	2025-08-29	2025-09-01	Checked-Out	28512.00	10.00	5006.86	0.00	Online	8553.60	2025-10-06 23:33:18.829019+05:30
1031	\N	99	44	2025-09-19	2025-09-21	Checked-Out	28512.00	10.00	5520.36	0.00	Online	5702.40	2025-10-06 23:33:18.829019+05:30
1038	\N	85	45	2025-07-16	2025-07-17	Checked-Out	24000.00	10.00	3453.13	0.00	Cash	2400.00	2025-10-06 23:33:18.829019+05:30
1053	\N	120	45	2025-09-05	2025-09-09	Checked-In	28512.00	10.00	3929.82	0.00	Cash	11404.80	2025-10-06 23:33:18.829019+05:30
1094	\N	71	47	2025-08-05	2025-08-08	Checked-Out	26400.00	10.00	4550.75	0.00	Cash	7920.00	2025-10-06 23:33:18.829019+05:30
1162	\N	95	50	2025-07-23	2025-07-24	Checked-In	18000.00	10.00	3144.20	0.00	Cash	1800.00	2025-10-06 23:33:18.829019+05:30
1167	\N	125	50	2025-08-05	2025-08-10	Checked-In	19800.00	10.00	1788.35	0.00	Cash	9900.00	2025-10-06 23:33:18.829019+05:30
1190	\N	147	51	2025-08-05	2025-08-06	Checked-In	19800.00	10.00	2623.92	0.00	BankTransfer	1980.00	2025-10-06 23:33:18.829019+05:30
1198	\N	14	51	2025-09-04	2025-09-07	Checked-Out	19800.00	10.00	2379.98	0.00	Cash	5940.00	2025-10-06 23:33:18.829019+05:30
1200	\N	119	51	2025-09-14	2025-09-15	Checked-In	19800.00	10.00	2692.43	0.00	Online	1980.00	2025-10-06 23:33:18.829019+05:30
1208	\N	138	52	2025-07-14	2025-07-18	Checked-In	18000.00	10.00	3148.88	0.00	Online	7200.00	2025-10-06 23:33:18.829019+05:30
553	\N	39	24	2025-08-02	2025-08-06	Checked-Out	28512.00	10.00	5676.40	0.00	Cash	11404.80	2025-10-06 23:33:18.829019+05:30
685	\N	149	29	2025-09-28	2025-10-01	Checked-Out	19800.00	10.00	3057.96	0.00	Card	5940.00	2025-10-06 23:33:18.829019+05:30
907	\N	30	39	2025-07-26	2025-07-31	Checked-Out	12960.00	10.00	2150.14	0.00	Cash	6480.00	2025-10-06 23:33:18.829019+05:30
1192	\N	144	51	2025-08-12	2025-08-16	Checked-Out	19800.00	10.00	3725.04	0.00	Online	7920.00	2025-10-06 23:33:18.829019+05:30
1243	\N	142	53	2025-08-30	2025-09-03	Checked-Out	21384.00	10.00	2527.00	0.00	Card	8553.60	2025-10-06 23:33:18.829019+05:30
763	\N	34	33	2025-08-30	2025-08-31	Checked-Out	21384.00	10.00	2626.72	0.00	Cash	2138.40	2025-10-06 23:33:18.829019+05:30
829	\N	101	36	2025-07-09	2025-07-11	Checked-Out	12000.00	10.00	1474.03	0.00	Cash	2400.00	2025-10-06 23:33:18.829019+05:30
834	\N	124	36	2025-07-25	2025-07-26	Checked-In	12960.00	10.00	1591.95	0.00	Online	1296.00	2025-10-06 23:33:18.829019+05:30
993	\N	79	43	2025-07-15	2025-07-18	Checked-Out	40000.00	10.00	4913.43	0.00	BankTransfer	12000.00	2025-10-06 23:33:18.829019+05:30
593	\N	65	26	2025-07-06	2025-07-10	Checked-Out	24000.00	10.00	3099.94	6426.01	BankTransfer	9600.00	2025-10-06 23:33:18.829019+05:30
623	\N	103	27	2025-08-09	2025-08-14	Checked-In	28512.00	10.00	4555.36	4335.29	Cash	14256.00	2025-10-06 23:33:18.829019+05:30
956	\N	16	41	2025-08-12	2025-08-16	Checked-Out	44000.00	10.00	2353.91	7443.93	Cash	17600.00	2025-10-06 23:33:18.829019+05:30
754	\N	16	33	2025-07-12	2025-07-17	Checked-Out	19440.00	10.00	2387.93	3467.87	Cash	9720.00	2025-10-06 23:33:18.829019+05:30
785	\N	133	34	2025-08-04	2025-08-05	Checked-Out	19800.00	10.00	2432.15	2427.68	Online	1980.00	2025-10-06 23:33:18.829019+05:30
1259	\N	2	54	2025-08-05	2025-08-09	Checked-Out	19800.00	10.00	1474.94	0.00	Cash	7920.00	2025-10-06 23:33:18.829019+05:30
1262	\N	104	54	2025-08-18	2025-08-20	Checked-Out	19800.00	10.00	3349.97	0.00	Online	3960.00	2025-10-06 23:33:18.829019+05:30
1264	\N	137	54	2025-08-23	2025-08-25	Checked-Out	21384.00	10.00	3589.62	0.00	Online	4276.80	2025-10-06 23:33:18.829019+05:30
1282	\N	137	55	2025-07-27	2025-07-31	Checked-Out	18000.00	10.00	2002.00	0.00	Cash	7200.00	2025-10-06 23:33:18.829019+05:30
1287	\N	85	55	2025-08-20	2025-08-22	Checked-Out	19800.00	10.00	2178.58	0.00	Card	3960.00	2025-10-06 23:33:18.829019+05:30
1290	\N	34	55	2025-08-31	2025-09-03	Checked-Out	19800.00	10.00	3459.11	0.00	Card	5940.00	2025-10-06 23:33:18.829019+05:30
1300	\N	50	56	2025-07-04	2025-07-07	Checked-Out	12960.00	10.00	1129.23	0.00	BankTransfer	3888.00	2025-10-06 23:33:18.829019+05:30
1308	\N	77	56	2025-08-03	2025-08-06	Checked-Out	13200.00	10.00	867.39	0.00	Cash	3960.00	2025-10-06 23:33:18.829019+05:30
1316	\N	93	56	2025-09-12	2025-09-14	Checked-In	14256.00	10.00	2222.37	0.00	BankTransfer	2851.20	2025-10-06 23:33:18.829019+05:30
1339	\N	130	57	2025-09-18	2025-09-20	Checked-Out	13200.00	10.00	1311.99	0.00	Card	2640.00	2025-10-06 23:33:18.829019+05:30
1352	\N	9	58	2025-08-05	2025-08-07	Checked-Out	13200.00	10.00	850.14	0.00	Online	2640.00	2025-10-06 23:33:18.829019+05:30
1372	\N	124	59	2025-08-01	2025-08-02	Checked-Out	14256.00	10.00	2405.31	0.00	Cash	1425.60	2025-10-06 23:33:18.829019+05:30
1382	\N	22	59	2025-09-12	2025-09-14	Checked-Out	14256.00	10.00	1597.66	0.00	Cash	2851.20	2025-10-06 23:33:18.829019+05:30
1403	\N	96	60	2025-09-05	2025-09-07	Checked-In	14256.00	10.00	2080.27	0.00	Online	2851.20	2025-10-06 23:33:18.829019+05:30
1405	\N	40	60	2025-09-13	2025-09-14	Checked-Out	14256.00	10.00	1199.50	0.00	Online	1425.60	2025-10-06 23:33:18.829019+05:30
459	\N	142	20	2025-08-09	2025-08-13	Checked-Out	14256.00	10.00	1280.98	0.00	Cash	5702.40	2025-10-06 23:33:18.829019+05:30
477	\N	77	21	2025-07-17	2025-07-19	Checked-Out	40000.00	10.00	7374.06	0.00	Cash	8000.00	2025-10-06 23:33:18.829019+05:30
486	\N	77	21	2025-08-29	2025-09-01	Checked-In	47520.00	10.00	7235.23	0.00	BankTransfer	14256.00	2025-10-06 23:33:18.829019+05:30
489	\N	44	21	2025-09-13	2025-09-16	Checked-Out	47520.00	10.00	5278.17	0.00	Cash	14256.00	2025-10-06 23:33:18.829019+05:30
675	\N	6	29	2025-08-17	2025-08-21	Checked-In	19800.00	10.00	3777.28	0.00	Online	7920.00	2025-10-06 23:33:18.829019+05:30
846	\N	116	36	2025-09-11	2025-09-16	Checked-Out	13200.00	10.00	2294.05	0.00	Cash	6600.00	2025-10-06 23:33:18.829019+05:30
853	\N	147	37	2025-07-05	2025-07-08	Checked-In	12960.00	10.00	2194.13	0.00	Cash	3888.00	2025-10-06 23:33:18.829019+05:30
152	\N	89	7	2025-08-05	2025-08-10	Checked-Out	26400.00	10.00	1427.69	0.00	Card	13200.00	2025-10-06 23:33:18.829019+05:30
1453	\N	1	20	2025-11-12	2025-11-14	Booked	20000.00	0.00	0.00	0.00	\N	5000.00	2025-10-07 20:12:53.650944+05:30
1457	\N	1	20	2025-11-14	2025-11-16	Booked	20000.00	0.00	0.00	0.00	\N	4000.00	2025-10-07 20:13:50.131468+05:30
1458	\N	1	20	2025-11-16	2025-11-18	Booked	20000.00	0.00	0.00	0.00	\N	4000.00	2025-10-07 20:19:55.782881+05:30
1406	\N	91	60	2025-09-15	2025-09-20	Checked-In	13200.00	10.00	1926.90	0.00	Cash	6600.00	2025-10-06 23:33:18.829019+05:30
63	\N	89	3	2025-09-03	2025-09-05	Checked-Out	44000.00	10.00	2862.76	0.00	BankTransfer	8800.00	2025-10-06 23:33:18.829019+05:30
64	\N	18	3	2025-09-06	2025-09-10	Checked-Out	47520.00	10.00	5905.57	0.00	Cash	19008.00	2025-10-06 23:33:18.829019+05:30
164	\N	67	7	2025-09-23	2025-09-25	Checked-Out	26400.00	10.00	2128.99	0.00	Cash	5280.00	2025-10-06 23:33:18.829019+05:30
300	\N	29	13	2025-08-30	2025-09-01	Checked-Out	21384.00	10.00	1510.63	0.00	Cash	4276.80	2025-10-06 23:33:18.829019+05:30
304	\N	101	13	2025-09-16	2025-09-21	Checked-Out	19800.00	10.00	3300.09	0.00	Card	9900.00	2025-10-06 23:33:18.829019+05:30
314	\N	136	14	2025-07-31	2025-08-05	Checked-Out	18000.00	10.00	3337.14	0.00	Card	9000.00	2025-10-06 23:33:18.829019+05:30
383	\N	141	17	2025-07-15	2025-07-18	Checked-In	12000.00	10.00	1702.10	0.00	Card	3600.00	2025-10-06 23:33:18.829019+05:30
396	\N	108	17	2025-09-13	2025-09-14	Checked-Out	14256.00	10.00	2429.15	0.00	BankTransfer	1425.60	2025-10-06 23:33:18.829019+05:30
463	\N	45	20	2025-08-24	2025-08-29	Checked-Out	13200.00	10.00	760.05	0.00	Online	6600.00	2025-10-06 23:33:18.829019+05:30
550	\N	145	24	2025-07-22	2025-07-24	Checked-Out	24000.00	10.00	1592.54	0.00	Cash	4800.00	2025-10-06 23:33:18.829019+05:30
888	\N	118	38	2025-08-12	2025-08-15	Checked-Out	13200.00	10.00	1610.23	0.00	BankTransfer	3960.00	2025-10-06 23:33:18.829019+05:30
1115	\N	82	48	2025-07-24	2025-07-25	Checked-Out	24000.00	10.00	2550.50	0.00	BankTransfer	2400.00	2025-10-06 23:33:18.829019+05:30
1132	\N	74	48	2025-09-21	2025-09-22	Checked-Out	26400.00	10.00	1911.92	0.00	Cash	2640.00	2025-10-06 23:33:18.829019+05:30
1134	\N	55	48	2025-09-29	2025-10-02	Checked-Out	26400.00	10.00	2493.03	0.00	Online	7920.00	2025-10-06 23:33:18.829019+05:30
1366	\N	65	59	2025-07-05	2025-07-09	Checked-Out	12960.00	10.00	1461.77	0.00	BankTransfer	5184.00	2025-10-06 23:33:18.829019+05:30
1369	\N	104	59	2025-07-17	2025-07-21	Checked-Out	12000.00	10.00	1556.79	0.00	Online	4800.00	2025-10-06 23:33:18.829019+05:30
25	\N	118	2	2025-07-12	2025-07-16	Checked-Out	43200.00	10.00	2503.28	0.00	Card	17280.00	2025-10-06 23:33:18.829019+05:30
34	\N	53	2	2025-08-13	2025-08-16	Checked-Out	44000.00	10.00	4984.25	0.00	Cash	13200.00	2025-10-06 23:33:18.829019+05:30
436	\N	101	19	2025-08-12	2025-08-13	Checked-In	13200.00	10.00	1339.87	0.00	Card	1320.00	2025-10-06 23:33:18.829019+05:30
635	\N	129	27	2025-09-24	2025-09-29	Checked-Out	26400.00	10.00	4404.89	0.00	Cash	13200.00	2025-10-06 23:33:18.829019+05:30
717	\N	57	31	2025-08-11	2025-08-14	Checked-Out	19800.00	10.00	1993.01	0.00	Cash	5940.00	2025-10-06 23:33:18.829019+05:30
911	\N	60	39	2025-08-12	2025-08-15	Checked-Out	13200.00	10.00	1199.94	0.00	Online	3960.00	2025-10-06 23:33:18.829019+05:30
1002	\N	111	43	2025-08-23	2025-08-27	Checked-In	47520.00	10.00	3484.10	0.00	Cash	19008.00	2025-10-06 23:33:18.829019+05:30
1014	\N	7	44	2025-07-10	2025-07-15	Checked-Out	24000.00	10.00	2299.07	0.00	Cash	12000.00	2025-10-06 23:33:18.829019+05:30
1027	\N	86	44	2025-09-06	2025-09-10	Checked-In	28512.00	10.00	1553.67	0.00	Cash	11404.80	2025-10-06 23:33:18.829019+05:30
1235	\N	144	53	2025-07-25	2025-07-27	Checked-Out	19440.00	10.00	3188.56	0.00	Cash	3888.00	2025-10-06 23:33:18.829019+05:30
1301	\N	64	56	2025-07-07	2025-07-08	Checked-In	12000.00	10.00	1406.54	0.00	Card	1200.00	2025-10-06 23:33:18.829019+05:30
210	\N	103	9	2025-09-25	2025-09-30	Checked-Out	19800.00	10.00	1072.20	0.00	BankTransfer	9900.00	2025-10-06 23:33:18.829019+05:30
442	\N	124	19	2025-08-30	2025-09-04	Checked-Out	14256.00	10.00	1396.48	0.00	Cash	7128.00	2025-10-06 23:33:18.829019+05:30
\.


--
-- TOC entry 5534 (class 0 OID 17217)
-- Dependencies: 224
-- Data for Name: branch; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.branch (branch_id, branch_name, contact_number, address, manager_name, branch_code) FROM stdin;
1	Colombo	011-236-1234	No. 1 Galle Road, Kollupitiya, Colombo 03	N. Silva	COL
2	Kandy	081-223-4567	38, Temple Street, Kandy	S. Perera	KAN
3	Galle	091-224-7890	12, Lighthouse Ave, Galle Fort, Galle	D. Fernando	GAL
\.


--
-- TOC entry 5536 (class 0 OID 17225)
-- Dependencies: 226
-- Data for Name: customer; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.customer (customer_id, user_id, guest_id, created_at) FROM stdin;
2	6	7	2025-10-05 15:02:36.044053+05:30
\.


--
-- TOC entry 5538 (class 0 OID 17232)
-- Dependencies: 228
-- Data for Name: employee; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.employee (employee_id, user_id, branch_id, name, email, contact_no) FROM stdin;
7	42	1	Manager Colombo	manager_colombo@skynest.com	0605379521
8	43	2	Manager Kandy	manager_kandy@skynest.com	0299773942
9	44	3	Manager Galle	manager_galle@skynest.com	0808175988
10	45	1	Recept Colombo	recept_colombo@skynest.com	0764460531
11	46	2	Recept Kandy	recept_kandy@skynest.com	0343942921
12	47	3	Recept Galle	recept_galle@skynest.com	0751293513
13	48	1	Accountant Colombo	accountant_colombo@skynest.com	0935540724
14	49	2	Accountant Kandy	accountant_kandy@skynest.com	0261705604
15	50	3	Accountant Galle	accountant_galle@skynest.com	0734487693
\.


--
-- TOC entry 5540 (class 0 OID 17240)
-- Dependencies: 230
-- Data for Name: guest; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.guest (guest_id, nic, full_name, email, phone, gender, date_of_birth, address, nationality) FROM stdin;
1	700000001V	Ishara Wickramasinghe	ishara.wickramasinghe1@example.com	072-6111617	\N	\N	\N	Sri Lankan
2	700000002V	Nadeesha Abeysekera	nadeesha.abeysekera2@example.com	077-3862809	\N	\N	\N	Sri Lankan
3	700000003V	Bhanuka Peiris	bhanuka.peiris3@example.com	078-0642602	\N	\N	\N	Sri Lankan
4	700000004V	Nuwan Bandara	nuwan.bandara4@example.com	078-0199525	\N	\N	\N	Sri Lankan
5	700000005V	Tharindu Jayasinghe	tharindu.jayasinghe5@example.com	078-4568005	\N	\N	\N	Sri Lankan
6	700000006V	Ayesha Ranasinghe	ayesha.ranasinghe6@example.com	074-6369236	\N	\N	\N	Sri Lankan
7	700000007V	Nuwan Peiris	nuwan.peiris7@example.com	071-8131247	\N	\N	\N	Sri Lankan
8	700000008V	Sachini Peiris	sachini.peiris8@example.com	072-3458606	\N	\N	\N	Sri Lankan
9	700000009V	Malith Wijesinghe	malith.wijesinghe9@example.com	073-3848861	\N	\N	\N	Sri Lankan
10	700000010V	Harini Perera	harini.perera10@example.com	076-4417421	\N	\N	\N	Sri Lankan
11	700000011V	Maneesha Peiris	maneesha.peiris11@example.com	071-6127680	\N	\N	\N	Sri Lankan
12	700000012V	Pramudi Perera	pramudi.perera12@example.com	077-7898841	\N	\N	\N	Sri Lankan
13	700000013V	Maneesha Wijesinghe	maneesha.wijesinghe13@example.com	074-0444887	\N	\N	\N	Sri Lankan
14	700000014V	Ayesha Bandara	ayesha.bandara14@example.com	075-0625147	\N	\N	\N	Sri Lankan
15	700000015V	Roshan Perera	roshan.perera15@example.com	074-7049978	\N	\N	\N	Sri Lankan
16	700000016V	Ishara Fernando	ishara.fernando16@example.com	071-3444405	\N	\N	\N	Sri Lankan
17	700000017V	Bhanuka Perera	bhanuka.perera17@example.com	072-7902099	\N	\N	\N	Sri Lankan
18	700000018V	Dinuka Jayasinghe	dinuka.jayasinghe18@example.com	071-6491447	\N	\N	\N	Sri Lankan
19	700000019V	Harini Wickramasinghe	harini.wickramasinghe19@example.com	072-2512118	\N	\N	\N	Sri Lankan
20	700000020V	Bhanuka Silva	bhanuka.silva20@example.com	078-3896233	\N	\N	\N	Sri Lankan
21	700000021V	Dulani Peiris	dulani.peiris21@example.com	075-0716788	\N	\N	\N	Sri Lankan
22	700000022V	Chamath Bandara	chamath.bandara22@example.com	077-6289248	\N	\N	\N	Sri Lankan
23	700000023V	Chamath Peiris	chamath.peiris23@example.com	074-8864345	\N	\N	\N	Sri Lankan
24	700000024V	Maneesha Gunasekara	maneesha.gunasekara24@example.com	071-8978168	\N	\N	\N	Sri Lankan
25	700000025V	Nadeesha Fernando	nadeesha.fernando25@example.com	077-5230318	\N	\N	\N	Sri Lankan
26	700000026V	Sachini Karunaratne	sachini.karunaratne26@example.com	074-9190926	\N	\N	\N	Sri Lankan
27	700000027V	Kasun Jayasinghe	kasun.jayasinghe27@example.com	071-0887659	\N	\N	\N	Sri Lankan
28	700000028V	Nimal Abeysekera	nimal.abeysekera28@example.com	077-3292255	\N	\N	\N	Sri Lankan
29	700000029V	Kavindu Abeysekera	kavindu.abeysekera29@example.com	076-6352676	\N	\N	\N	Sri Lankan
30	700000030V	Lakmini Wickramasinghe	lakmini.wickramasinghe30@example.com	075-6731176	\N	\N	\N	Sri Lankan
31	700000031V	Sachini Ranasinghe	sachini.ranasinghe31@example.com	073-4012689	\N	\N	\N	Sri Lankan
32	700000032V	Nuwan Ranasinghe	nuwan.ranasinghe32@example.com	074-9833776	\N	\N	\N	Sri Lankan
33	700000033V	Roshan Peiris	roshan.peiris33@example.com	072-9296200	\N	\N	\N	Sri Lankan
34	700000034V	Malith Ekanayake	malith.ekanayake34@example.com	077-9230454	\N	\N	\N	Sri Lankan
35	700000035V	Lakmini Weerasinghe	lakmini.weerasinghe35@example.com	077-8319123	\N	\N	\N	Sri Lankan
36	700000036V	Dinuka Fernando	dinuka.fernando36@example.com	072-4982723	\N	\N	\N	Sri Lankan
37	700000037V	Kavindu Wijesinghe	kavindu.wijesinghe37@example.com	075-8727855	\N	\N	\N	Sri Lankan
38	700000038V	Sanduni Gunasekara	sanduni.gunasekara38@example.com	074-1771443	\N	\N	\N	Sri Lankan
39	700000039V	Kavindu Ranasinghe	kavindu.ranasinghe39@example.com	071-7768346	\N	\N	\N	Sri Lankan
40	700000040V	Supun Fernando	supun.fernando40@example.com	072-1392584	\N	\N	\N	Sri Lankan
41	700000041V	Pramudi Fernando	pramudi.fernando41@example.com	073-3756844	\N	\N	\N	Sri Lankan
42	700000042V	Chathura Karunaratne	chathura.karunaratne42@example.com	075-6970848	\N	\N	\N	Sri Lankan
43	700000043V	Dinuka Silva	dinuka.silva43@example.com	073-9020758	\N	\N	\N	Sri Lankan
44	700000044V	Maneesha Bandara	maneesha.bandara44@example.com	077-4300393	\N	\N	\N	Sri Lankan
45	700000045V	Pramudi Silva	pramudi.silva45@example.com	073-8990372	\N	\N	\N	Sri Lankan
46	700000046V	Ruwan Ranasinghe	ruwan.ranasinghe46@example.com	077-1106828	\N	\N	\N	Sri Lankan
47	700000047V	Sanduni Silva	sanduni.silva47@example.com	072-4474953	\N	\N	\N	Sri Lankan
48	700000048V	Sajith Ranasinghe	sajith.ranasinghe48@example.com	071-6839948	\N	\N	\N	Sri Lankan
49	700000049V	Chamath Abeysekera	chamath.abeysekera49@example.com	072-7230963	\N	\N	\N	Sri Lankan
50	700000050V	Dulani Jayasinghe	dulani.jayasinghe50@example.com	073-6857193	\N	\N	\N	Sri Lankan
51	700000051V	Shenal Perera	shenal.perera51@example.com	072-2375825	\N	\N	\N	Sri Lankan
52	700000052V	Hasini Karunaratne	hasini.karunaratne52@example.com	078-4623101	\N	\N	\N	Sri Lankan
53	700000053V	Tharindu Weerasinghe	tharindu.weerasinghe53@example.com	073-4246350	\N	\N	\N	Sri Lankan
54	700000054V	Malith Abeysekera	malith.abeysekera54@example.com	073-9929454	\N	\N	\N	Sri Lankan
55	700000055V	Nuwan Jayasinghe	nuwan.jayasinghe55@example.com	076-3914467	\N	\N	\N	Sri Lankan
56	700000056V	Ishara Weerasinghe	ishara.weerasinghe56@example.com	076-7836495	\N	\N	\N	Sri Lankan
57	700000057V	Maneesha Fernando	maneesha.fernando57@example.com	075-0511688	\N	\N	\N	Sri Lankan
58	700000058V	Chamath Ekanayake	chamath.ekanayake58@example.com	074-7854520	\N	\N	\N	Sri Lankan
59	700000059V	Roshan Wijesinghe	roshan.wijesinghe59@example.com	076-8258014	\N	\N	\N	Sri Lankan
60	700000060V	Ayesha Peiris	ayesha.peiris60@example.com	075-6326572	\N	\N	\N	Sri Lankan
61	700000061V	Thisara Abeysekera	thisara.abeysekera61@example.com	077-8513260	\N	\N	\N	Sri Lankan
62	700000062V	Shenal Fernando	shenal.fernando62@example.com	077-1117659	\N	\N	\N	Sri Lankan
63	700000063V	Ayesha Silva	ayesha.silva63@example.com	075-0871460	\N	\N	\N	Sri Lankan
64	700000064V	Nimal Silva	nimal.silva64@example.com	077-8005969	\N	\N	\N	Sri Lankan
65	700000065V	Shenal Gunasekara	shenal.gunasekara65@example.com	075-0892574	\N	\N	\N	Sri Lankan
66	700000066V	Bhanuka Ranasinghe	bhanuka.ranasinghe66@example.com	076-3178336	\N	\N	\N	Sri Lankan
67	700000067V	Kasun Ranasinghe	kasun.ranasinghe67@example.com	076-8187023	\N	\N	\N	Sri Lankan
68	700000068V	Maneesha Jayasinghe	maneesha.jayasinghe68@example.com	076-9650382	\N	\N	\N	Sri Lankan
69	700000069V	Chamath Ranasinghe	chamath.ranasinghe69@example.com	071-3897528	\N	\N	\N	Sri Lankan
70	700000070V	Thisara Fernando	thisara.fernando70@example.com	074-0156296	\N	\N	\N	Sri Lankan
71	700000071V	Nuwan Peiris	nuwan.peiris71@example.com	076-7345482	\N	\N	\N	Sri Lankan
72	700000072V	Ishani Jayasinghe	ishani.jayasinghe72@example.com	076-7490544	\N	\N	\N	Sri Lankan
73	700000073V	Pasindu Weerasinghe	pasindu.weerasinghe73@example.com	078-6904699	\N	\N	\N	Sri Lankan
74	700000074V	Nuwan Wijesinghe	nuwan.wijesinghe74@example.com	071-1760566	\N	\N	\N	Sri Lankan
75	700000075V	Shenal Ranasinghe	shenal.ranasinghe75@example.com	071-2735496	\N	\N	\N	Sri Lankan
76	700000076V	Dulani Abeysekera	dulani.abeysekera76@example.com	078-2875830	\N	\N	\N	Sri Lankan
77	700000077V	Roshan Gunasekara	roshan.gunasekara77@example.com	073-4317972	\N	\N	\N	Sri Lankan
78	700000078V	Harini Wickramasinghe	harini.wickramasinghe78@example.com	073-1837352	\N	\N	\N	Sri Lankan
79	700000079V	Malith Ranasinghe	malith.ranasinghe79@example.com	077-2085172	\N	\N	\N	Sri Lankan
80	700000080V	Tharindu Karunaratne	tharindu.karunaratne80@example.com	071-0672868	\N	\N	\N	Sri Lankan
81	700000081V	Chathura Wijesinghe	chathura.wijesinghe81@example.com	077-2714987	\N	\N	\N	Sri Lankan
82	700000082V	Dulani Gunasekara	dulani.gunasekara82@example.com	076-3983765	\N	\N	\N	Sri Lankan
83	700000083V	Ishani Ranasinghe	ishani.ranasinghe83@example.com	077-0521359	\N	\N	\N	Sri Lankan
84	700000084V	Nadeesha Abeysekera	nadeesha.abeysekera84@example.com	076-9415793	\N	\N	\N	Sri Lankan
85	700000085V	Bhanuka Wickramasinghe	bhanuka.wickramasinghe85@example.com	072-3532273	\N	\N	\N	Sri Lankan
86	700000086V	Lakmini Ekanayake	lakmini.ekanayake86@example.com	077-1553244	\N	\N	\N	Sri Lankan
87	700000087V	Nimal Peiris	nimal.peiris87@example.com	078-5773136	\N	\N	\N	Sri Lankan
88	700000088V	Nimal Perera	nimal.perera88@example.com	077-3371763	\N	\N	\N	Sri Lankan
89	700000089V	Roshan Jayasinghe	roshan.jayasinghe89@example.com	071-3703308	\N	\N	\N	Sri Lankan
90	700000090V	Nuwan Abeysekera	nuwan.abeysekera90@example.com	076-7884506	\N	\N	\N	Sri Lankan
91	700000091V	Malith Bandara	malith.bandara91@example.com	072-8425297	\N	\N	\N	Sri Lankan
92	700000092V	Kavindu Ranasinghe	kavindu.ranasinghe92@example.com	074-0948805	\N	\N	\N	Sri Lankan
93	700000093V	Hasini Silva	hasini.silva93@example.com	075-0318477	\N	\N	\N	Sri Lankan
94	700000094V	Sanduni Silva	sanduni.silva94@example.com	075-4543481	\N	\N	\N	Sri Lankan
95	700000095V	Shenal Gunasekara	shenal.gunasekara95@example.com	078-8640740	\N	\N	\N	Sri Lankan
96	700000096V	Chathura Karunaratne	chathura.karunaratne96@example.com	071-9263260	\N	\N	\N	Sri Lankan
97	700000097V	Ishani Peiris	ishani.peiris97@example.com	076-6743070	\N	\N	\N	Sri Lankan
98	700000098V	Sachini Ranasinghe	sachini.ranasinghe98@example.com	075-1420007	\N	\N	\N	Sri Lankan
99	700000099V	Ruwan Karunaratne	ruwan.karunaratne99@example.com	073-1964512	\N	\N	\N	Sri Lankan
100	700000100V	Sajith Jayasinghe	sajith.jayasinghe100@example.com	076-6755655	\N	\N	\N	Sri Lankan
101	700000101V	Hasini Ekanayake	hasini.ekanayake101@example.com	076-2316679	\N	\N	\N	Sri Lankan
102	700000102V	Hasini Bandara	hasini.bandara102@example.com	075-2091641	\N	\N	\N	Sri Lankan
103	700000103V	Pasindu Gunasekara	pasindu.gunasekara103@example.com	074-9558258	\N	\N	\N	Sri Lankan
104	700000104V	Pramudi Karunaratne	pramudi.karunaratne104@example.com	071-4971142	\N	\N	\N	Sri Lankan
105	700000105V	Lakmini Weerasinghe	lakmini.weerasinghe105@example.com	073-3322936	\N	\N	\N	Sri Lankan
106	700000106V	Kavindu Fernando	kavindu.fernando106@example.com	074-2338592	\N	\N	\N	Sri Lankan
107	700000107V	Nimal Abeysekera	nimal.abeysekera107@example.com	078-6937480	\N	\N	\N	Sri Lankan
108	700000108V	Hasini Silva	hasini.silva108@example.com	074-3934589	\N	\N	\N	Sri Lankan
109	700000109V	Chamath Abeysekera	chamath.abeysekera109@example.com	078-1624488	\N	\N	\N	Sri Lankan
110	700000110V	Dinuka Karunaratne	dinuka.karunaratne110@example.com	077-1009271	\N	\N	\N	Sri Lankan
111	700000111V	Tharindu Fernando	tharindu.fernando111@example.com	073-1467102	\N	\N	\N	Sri Lankan
112	700000112V	Sajith Gunasekara	sajith.gunasekara112@example.com	074-2990420	\N	\N	\N	Sri Lankan
113	700000113V	Malith Fernando	malith.fernando113@example.com	073-1437983	\N	\N	\N	Sri Lankan
114	700000114V	Nuwan Fernando	nuwan.fernando114@example.com	072-6939343	\N	\N	\N	Sri Lankan
115	700000115V	Pramudi Bandara	pramudi.bandara115@example.com	076-9499734	\N	\N	\N	Sri Lankan
116	700000116V	Lakmini Perera	lakmini.perera116@example.com	072-4313097	\N	\N	\N	Sri Lankan
117	700000117V	Kavindu Gunasekara	kavindu.gunasekara117@example.com	075-1486708	\N	\N	\N	Sri Lankan
118	700000118V	Lakmini Peiris	lakmini.peiris118@example.com	073-0339646	\N	\N	\N	Sri Lankan
119	700000119V	Malith Silva	malith.silva119@example.com	073-5769492	\N	\N	\N	Sri Lankan
120	700000120V	Supun Abeysekera	supun.abeysekera120@example.com	072-0485947	\N	\N	\N	Sri Lankan
121	700000121V	Nuwan Ranasinghe	nuwan.ranasinghe121@example.com	073-4090730	\N	\N	\N	Sri Lankan
122	700000122V	Pasindu Silva	pasindu.silva122@example.com	078-1369365	\N	\N	\N	Sri Lankan
123	700000123V	Thisara Fernando	thisara.fernando123@example.com	072-7463054	\N	\N	\N	Sri Lankan
124	700000124V	Ishara Perera	ishara.perera124@example.com	072-8481763	\N	\N	\N	Sri Lankan
125	700000125V	Pasindu Abeysekera	pasindu.abeysekera125@example.com	076-4148286	\N	\N	\N	Sri Lankan
126	700000126V	Dulani Bandara	dulani.bandara126@example.com	073-2275088	\N	\N	\N	Sri Lankan
127	700000127V	Maneesha Ranasinghe	maneesha.ranasinghe127@example.com	075-0745110	\N	\N	\N	Sri Lankan
128	700000128V	Pasindu Abeysekera	pasindu.abeysekera128@example.com	073-2602365	\N	\N	\N	Sri Lankan
129	700000129V	Hasini Abeysekera	hasini.abeysekera129@example.com	078-3531571	\N	\N	\N	Sri Lankan
130	700000130V	Ishara Karunaratne	ishara.karunaratne130@example.com	077-7685944	\N	\N	\N	Sri Lankan
131	700000131V	Kasun Weerasinghe	kasun.weerasinghe131@example.com	073-0153251	\N	\N	\N	Sri Lankan
132	700000132V	Dulani Wickramasinghe	dulani.wickramasinghe132@example.com	078-5092251	\N	\N	\N	Sri Lankan
133	700000133V	Dinuka Weerasinghe	dinuka.weerasinghe133@example.com	072-9559854	\N	\N	\N	Sri Lankan
134	700000134V	Supun Wickramasinghe	supun.wickramasinghe134@example.com	074-3555249	\N	\N	\N	Sri Lankan
135	700000135V	Pasindu Ranasinghe	pasindu.ranasinghe135@example.com	075-1252679	\N	\N	\N	Sri Lankan
136	700000136V	Roshan Fernando	roshan.fernando136@example.com	074-1314324	\N	\N	\N	Sri Lankan
137	700000137V	Lakmini Wickramasinghe	lakmini.wickramasinghe137@example.com	077-9964438	\N	\N	\N	Sri Lankan
138	700000138V	Sanduni Ranasinghe	sanduni.ranasinghe138@example.com	073-1282723	\N	\N	\N	Sri Lankan
139	700000139V	Ishani Wijesinghe	ishani.wijesinghe139@example.com	077-8292672	\N	\N	\N	Sri Lankan
140	700000140V	Tharindu Abeysekera	tharindu.abeysekera140@example.com	075-6847106	\N	\N	\N	Sri Lankan
141	700000141V	Hasini Karunaratne	hasini.karunaratne141@example.com	078-5649804	\N	\N	\N	Sri Lankan
142	700000142V	Ishani Silva	ishani.silva142@example.com	078-3300722	\N	\N	\N	Sri Lankan
143	700000143V	Pasindu Jayasinghe	pasindu.jayasinghe143@example.com	076-9845485	\N	\N	\N	Sri Lankan
144	700000144V	Ishara Jayasinghe	ishara.jayasinghe144@example.com	078-9595790	\N	\N	\N	Sri Lankan
145	700000145V	Kasun Jayasinghe	kasun.jayasinghe145@example.com	073-3096719	\N	\N	\N	Sri Lankan
146	700000146V	Dinuka Karunaratne	dinuka.karunaratne146@example.com	077-0915936	\N	\N	\N	Sri Lankan
147	700000147V	Pasindu Perera	pasindu.perera147@example.com	077-9514435	\N	\N	\N	Sri Lankan
148	700000148V	Tharindu Wijesinghe	tharindu.wijesinghe148@example.com	075-9685992	\N	\N	\N	Sri Lankan
149	700000149V	Sachini Bandara	sachini.bandara149@example.com	074-9561128	\N	\N	\N	Sri Lankan
150	700000150V	Sanduni Ekanayake	sanduni.ekanayake150@example.com	073-5801800	\N	\N	\N	Sri Lankan
151	\N	*** MAINTENANCE ***	maintenance@skynest.local	\N	\N	\N	\N	\N
\.


--
-- TOC entry 5542 (class 0 OID 17248)
-- Dependencies: 232
-- Data for Name: invoice; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.invoice (invoice_id, booking_id, period_start, period_end, issued_at) FROM stdin;
\.


--
-- TOC entry 5544 (class 0 OID 17256)
-- Dependencies: 234
-- Data for Name: payment; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.payment (payment_id, booking_id, amount, method, paid_at, payment_reference) FROM stdin;
1431	3	22271.94	Cash	2025-10-05 15:02:17.08014+05:30	\N
2	1	214500.00	Card	2025-10-05 14:48:35.805126+05:30	\N
3	3	122416.21	Cash	2025-10-05 14:48:35.805126+05:30	\N
4	4	141817.85	Cash	2025-10-05 14:48:35.805126+05:30	\N
5	5	202950.00	Card	2025-10-05 14:48:35.805126+05:30	\N
6	6	191789.57	Cash	2025-10-05 14:48:35.805126+05:30	\N
7	6	64950.43	Online	2025-10-05 14:48:35.805126+05:30	\N
8	7	135850.00	Card	2025-10-05 14:48:35.805126+05:30	\N
9	8	234217.03	Cash	2025-10-05 14:48:35.805126+05:30	\N
10	9	209088.00	Card	2025-10-05 14:48:35.805126+05:30	\N
11	10	343200.00	Card	2025-10-05 14:48:35.805126+05:30	\N
12	11	193600.00	Card	2025-10-05 14:48:35.805126+05:30	\N
13	12	209088.00	Card	2025-10-05 14:48:35.805126+05:30	\N
14	13	58212.00	Card	2025-10-05 14:48:35.805126+05:30	\N
15	14	29754.92	Cash	2025-10-05 14:48:35.805126+05:30	\N
16	14	17529.96	Online	2025-10-05 14:48:35.805126+05:30	\N
17	15	225280.00	Card	2025-10-05 14:48:35.805126+05:30	\N
18	16	261360.00	Card	2025-10-05 14:48:35.805126+05:30	\N
19	18	193600.00	Card	2025-10-05 14:48:35.805126+05:30	\N
20	19	121022.00	Card	2025-10-05 14:48:35.805126+05:30	\N
21	20	151800.00	Card	2025-10-05 14:48:35.805126+05:30	\N
22	21	197410.82	Cash	2025-10-05 14:48:35.805126+05:30	\N
23	21	117763.45	Online	2025-10-05 14:48:35.805126+05:30	\N
24	22	132000.00	Card	2025-10-05 14:48:35.805126+05:30	\N
25	23	231880.00	Card	2025-10-05 14:48:35.805126+05:30	\N
26	24	184800.00	Card	2025-10-05 14:48:35.805126+05:30	\N
27	25	220660.00	Card	2025-10-05 14:48:35.805126+05:30	\N
28	26	88000.00	Card	2025-10-05 14:48:35.805126+05:30	\N
29	27	176000.00	Card	2025-10-05 14:48:35.805126+05:30	\N
30	28	169070.00	Card	2025-10-05 14:48:35.805126+05:30	\N
31	29	48736.76	Cash	2025-10-05 14:48:35.805126+05:30	\N
32	29	20210.60	Online	2025-10-05 14:48:35.805126+05:30	\N
33	30	30024.19	Cash	2025-10-05 14:48:35.805126+05:30	\N
34	30	7305.45	Online	2025-10-05 14:48:35.805126+05:30	\N
35	31	111207.00	Cash	2025-10-05 14:48:35.805126+05:30	\N
36	32	219340.00	Card	2025-10-05 14:48:35.805126+05:30	\N
37	33	129470.00	Card	2025-10-05 14:48:35.805126+05:30	\N
38	34	226050.00	Card	2025-10-05 14:48:35.805126+05:30	\N
39	35	151910.00	Card	2025-10-05 14:48:35.805126+05:30	\N
40	36	154131.71	Cash	2025-10-05 14:48:35.805126+05:30	\N
41	37	115893.48	Cash	2025-10-05 14:48:35.805126+05:30	\N
42	38	36368.53	Cash	2025-10-05 14:48:35.805126+05:30	\N
43	38	15047.54	Online	2025-10-05 14:48:35.805126+05:30	\N
44	39	101038.84	Cash	2025-10-05 14:48:35.805126+05:30	\N
45	39	59460.39	Online	2025-10-05 14:48:35.805126+05:30	\N
46	40	165000.00	Card	2025-10-05 14:48:35.805126+05:30	\N
47	41	149999.08	Cash	2025-10-05 14:48:35.805126+05:30	\N
48	41	102344.86	Online	2025-10-05 14:48:35.805126+05:30	\N
49	42	211200.00	Card	2025-10-05 14:48:35.805126+05:30	\N
50	43	201459.67	Cash	2025-10-05 14:48:35.805126+05:30	\N
51	44	200939.04	Cash	2025-10-05 14:48:35.805126+05:30	\N
52	46	235180.00	Card	2025-10-05 14:48:35.805126+05:30	\N
53	49	34464.95	Cash	2025-10-05 14:48:35.805126+05:30	\N
54	49	26449.25	Online	2025-10-05 14:48:35.805126+05:30	\N
55	51	125747.42	Cash	2025-10-05 14:48:35.805126+05:30	\N
56	52	127600.00	Card	2025-10-05 14:48:35.805126+05:30	\N
57	53	110067.31	Cash	2025-10-05 14:48:35.805126+05:30	\N
58	53	29632.69	Online	2025-10-05 14:48:35.805126+05:30	\N
59	54	173580.00	Card	2025-10-05 14:48:35.805126+05:30	\N
60	55	125745.72	Cash	2025-10-05 14:48:35.805126+05:30	\N
61	55	61160.80	Online	2025-10-05 14:48:35.805126+05:30	\N
62	57	158136.00	Card	2025-10-05 14:48:35.805126+05:30	\N
63	58	116600.00	Card	2025-10-05 14:48:35.805126+05:30	\N
64	59	145200.00	Card	2025-10-05 14:48:35.805126+05:30	\N
65	60	97402.40	Cash	2025-10-05 14:48:35.805126+05:30	\N
66	62	193600.00	Card	2025-10-05 14:48:35.805126+05:30	\N
67	64	222948.00	Card	2025-10-05 14:48:35.805126+05:30	\N
68	65	215380.00	Card	2025-10-05 14:48:35.805126+05:30	\N
69	66	246400.00	Card	2025-10-05 14:48:35.805126+05:30	\N
70	67	262900.00	Card	2025-10-05 14:48:35.805126+05:30	\N
71	69	178978.98	Cash	2025-10-05 14:48:35.805126+05:30	\N
72	69	83371.02	Online	2025-10-05 14:48:35.805126+05:30	\N
73	70	79200.00	Card	2025-10-05 14:48:35.805126+05:30	\N
74	71	144856.07	Cash	2025-10-05 14:48:35.805126+05:30	\N
75	72	75240.00	Card	2025-10-05 14:48:35.805126+05:30	\N
76	73	162624.00	Card	2025-10-05 14:48:35.805126+05:30	\N
77	74	129690.00	Card	2025-10-05 14:48:35.805126+05:30	\N
78	75	110440.00	Card	2025-10-05 14:48:35.805126+05:30	\N
79	76	64944.00	Card	2025-10-05 14:48:35.805126+05:30	\N
80	77	90200.00	Card	2025-10-05 14:48:35.805126+05:30	\N
81	79	76476.98	Cash	2025-10-05 14:48:35.805126+05:30	\N
82	81	162729.60	Card	2025-10-05 14:48:35.805126+05:30	\N
83	83	39974.86	Cash	2025-10-05 14:48:35.805126+05:30	\N
84	83	20882.48	Online	2025-10-05 14:48:35.805126+05:30	\N
85	84	87120.00	Card	2025-10-05 14:48:35.805126+05:30	\N
86	85	90420.00	Card	2025-10-05 14:48:35.805126+05:30	\N
87	86	166650.00	Card	2025-10-05 14:48:35.805126+05:30	\N
88	87	104942.33	Cash	2025-10-05 14:48:35.805126+05:30	\N
89	88	162800.00	Card	2025-10-05 14:48:35.805126+05:30	\N
90	90	65556.57	Cash	2025-10-05 14:48:35.805126+05:30	\N
91	91	74263.20	Card	2025-10-05 14:48:35.805126+05:30	\N
92	93	106590.00	Card	2025-10-05 14:48:35.805126+05:30	\N
93	94	58740.00	Card	2025-10-05 14:48:35.805126+05:30	\N
94	95	39723.32	Cash	2025-10-05 14:48:35.805126+05:30	\N
95	96	106260.00	Card	2025-10-05 14:48:35.805126+05:30	\N
96	97	153120.00	Card	2025-10-05 14:48:35.805126+05:30	\N
97	98	77462.00	Card	2025-10-05 14:48:35.805126+05:30	\N
98	99	69327.32	Cash	2025-10-05 14:48:35.805126+05:30	\N
99	99	28716.46	Online	2025-10-05 14:48:35.805126+05:30	\N
100	100	105600.00	Card	2025-10-05 14:48:35.805126+05:30	\N
101	101	160248.00	Card	2025-10-05 14:48:35.805126+05:30	\N
102	102	91926.35	Cash	2025-10-05 14:48:35.805126+05:30	\N
103	103	184800.00	Card	2025-10-05 14:48:35.805126+05:30	\N
104	104	162140.00	Card	2025-10-05 14:48:35.805126+05:30	\N
105	105	68116.40	Card	2025-10-05 14:48:35.805126+05:30	\N
106	106	122100.00	Card	2025-10-05 14:48:35.805126+05:30	\N
107	108	250800.00	Card	2025-10-05 14:48:35.805126+05:30	\N
108	109	136620.00	Card	2025-10-05 14:48:35.805126+05:30	\N
109	110	98340.00	Card	2025-10-05 14:48:35.805126+05:30	\N
110	111	96587.11	Cash	2025-10-05 14:48:35.805126+05:30	\N
111	111	20101.16	Online	2025-10-05 14:48:35.805126+05:30	\N
112	112	115940.00	Card	2025-10-05 14:48:35.805126+05:30	\N
113	115	132660.00	Card	2025-10-05 14:48:35.805126+05:30	\N
114	116	125452.80	Card	2025-10-05 14:48:35.805126+05:30	\N
115	117	135300.00	Card	2025-10-05 14:48:35.805126+05:30	\N
116	118	28512.00	Card	2025-10-05 14:48:35.805126+05:30	\N
117	119	131450.00	Card	2025-10-05 14:48:35.805126+05:30	\N
118	120	57269.10	Cash	2025-10-05 14:48:35.805126+05:30	\N
119	120	16118.31	Online	2025-10-05 14:48:35.805126+05:30	\N
120	121	52800.00	Card	2025-10-05 14:48:35.805126+05:30	\N
121	122	198110.00	Card	2025-10-05 14:48:35.805126+05:30	\N
122	123	163548.00	Card	2025-10-05 14:48:35.805126+05:30	\N
123	124	32996.51	Cash	2025-10-05 14:48:35.805126+05:30	\N
124	125	14064.00	Cash	2025-10-05 14:48:35.805126+05:30	\N
125	126	74474.92	Cash	2025-10-05 14:48:35.805126+05:30	\N
126	126	34985.98	Online	2025-10-05 14:48:35.805126+05:30	\N
127	127	88440.00	Card	2025-10-05 14:48:35.805126+05:30	\N
128	128	49920.91	Cash	2025-10-05 14:48:35.805126+05:30	\N
129	129	82865.70	Cash	2025-10-05 14:48:35.805126+05:30	\N
130	130	64584.02	Cash	2025-10-05 14:48:35.805126+05:30	\N
131	130	48636.17	Online	2025-10-05 14:48:35.805126+05:30	\N
132	131	94089.60	Card	2025-10-05 14:48:35.805126+05:30	\N
133	134	94089.60	Card	2025-10-05 14:48:35.805126+05:30	\N
134	136	112640.00	Card	2025-10-05 14:48:35.805126+05:30	\N
135	137	110440.00	Card	2025-10-05 14:48:35.805126+05:30	\N
136	138	80863.20	Card	2025-10-05 14:48:35.805126+05:30	\N
137	139	27324.95	Cash	2025-10-05 14:48:35.805126+05:30	\N
138	139	29154.16	Online	2025-10-05 14:48:35.805126+05:30	\N
139	140	165066.00	Card	2025-10-05 14:48:35.805126+05:30	\N
140	141	135326.40	Card	2025-10-05 14:48:35.805126+05:30	\N
141	142	29040.00	Card	2025-10-05 14:48:35.805126+05:30	\N
142	144	38095.28	Cash	2025-10-05 14:48:35.805126+05:30	\N
143	144	29939.02	Online	2025-10-05 14:48:35.805126+05:30	\N
144	145	111936.00	Card	2025-10-05 14:48:35.805126+05:30	\N
145	146	124960.00	Card	2025-10-05 14:48:35.805126+05:30	\N
146	147	90200.00	Card	2025-10-05 14:48:35.805126+05:30	\N
147	149	135850.00	Card	2025-10-05 14:48:35.805126+05:30	\N
148	150	114400.00	Card	2025-10-05 14:48:35.805126+05:30	\N
149	151	73649.80	Cash	2025-10-05 14:48:35.805126+05:30	\N
150	151	28643.21	Online	2025-10-05 14:48:35.805126+05:30	\N
151	152	68673.02	Cash	2025-10-05 14:48:35.805126+05:30	\N
152	153	76996.86	Cash	2025-10-05 14:48:35.805126+05:30	\N
153	154	119240.00	Card	2025-10-05 14:48:35.805126+05:30	\N
154	155	119460.00	Card	2025-10-05 14:48:35.805126+05:30	\N
155	156	66949.18	Cash	2025-10-05 14:48:35.805126+05:30	\N
156	157	192720.00	Card	2025-10-05 14:48:35.805126+05:30	\N
157	158	123459.60	Card	2025-10-05 14:48:35.805126+05:30	\N
158	159	122870.00	Card	2025-10-05 14:48:35.805126+05:30	\N
159	160	110225.39	Cash	2025-10-05 14:48:35.805126+05:30	\N
160	160	40050.34	Online	2025-10-05 14:48:35.805126+05:30	\N
161	161	116567.54	Cash	2025-10-05 14:48:35.805126+05:30	\N
162	161	29465.75	Online	2025-10-05 14:48:35.805126+05:30	\N
163	162	135602.13	Cash	2025-10-05 14:48:35.805126+05:30	\N
164	162	34347.87	Online	2025-10-05 14:48:35.805126+05:30	\N
165	163	190080.00	Card	2025-10-05 14:48:35.805126+05:30	\N
166	165	120971.79	Cash	2025-10-05 14:48:35.805126+05:30	\N
167	166	144540.00	Card	2025-10-05 14:48:35.805126+05:30	\N
168	167	79200.00	Card	2025-10-05 14:48:35.805126+05:30	\N
169	168	49601.82	Cash	2025-10-05 14:48:35.805126+05:30	\N
170	168	15897.60	Online	2025-10-05 14:48:35.805126+05:30	\N
171	169	92312.00	Card	2025-10-05 14:48:35.805126+05:30	\N
172	170	164780.00	Card	2025-10-05 14:48:35.805126+05:30	\N
173	171	98564.84	Cash	2025-10-05 14:48:35.805126+05:30	\N
174	174	53198.15	Cash	2025-10-05 14:48:35.805126+05:30	\N
175	175	105600.00	Card	2025-10-05 14:48:35.805126+05:30	\N
176	176	73937.56	Cash	2025-10-05 14:48:35.805126+05:30	\N
177	176	14633.83	Online	2025-10-05 14:48:35.805126+05:30	\N
178	177	164516.00	Card	2025-10-05 14:48:35.805126+05:30	\N
179	179	89931.18	Cash	2025-10-05 14:48:35.805126+05:30	\N
180	179	57483.45	Online	2025-10-05 14:48:35.805126+05:30	\N
181	180	72444.72	Cash	2025-10-05 14:48:35.805126+05:30	\N
182	181	15781.57	Cash	2025-10-05 14:48:35.805126+05:30	\N
183	182	140826.40	Card	2025-10-05 14:48:35.805126+05:30	\N
184	183	42431.91	Cash	2025-10-05 14:48:35.805126+05:30	\N
185	183	32098.83	Online	2025-10-05 14:48:35.805126+05:30	\N
186	185	74041.37	Cash	2025-10-05 14:48:35.805126+05:30	\N
187	185	45837.96	Online	2025-10-05 14:48:35.805126+05:30	\N
188	186	58080.00	Card	2025-10-05 14:48:35.805126+05:30	\N
189	187	98230.00	Card	2025-10-05 14:48:35.805126+05:30	\N
190	188	160160.00	Card	2025-10-05 14:48:35.805126+05:30	\N
191	190	70089.99	Cash	2025-10-05 14:48:35.805126+05:30	\N
192	191	48189.04	Cash	2025-10-05 14:48:35.805126+05:30	\N
193	193	77220.00	Card	2025-10-05 14:48:35.805126+05:30	\N
194	196	10637.73	Cash	2025-10-05 14:48:35.805126+05:30	\N
195	197	66000.00	Card	2025-10-05 14:48:35.805126+05:30	\N
196	198	150739.60	Card	2025-10-05 14:48:35.805126+05:30	\N
197	199	87250.81	Cash	2025-10-05 14:48:35.805126+05:30	\N
198	200	52762.40	Cash	2025-10-05 14:48:35.805126+05:30	\N
199	201	33293.83	Cash	2025-10-05 14:48:35.805126+05:30	\N
200	202	151250.00	Card	2025-10-05 14:48:35.805126+05:30	\N
201	203	113520.00	Card	2025-10-05 14:48:35.805126+05:30	\N
202	204	81510.00	Card	2025-10-05 14:48:35.805126+05:30	\N
203	206	25080.00	Card	2025-10-05 14:48:35.805126+05:30	\N
204	207	77253.85	Cash	2025-10-05 14:48:35.805126+05:30	\N
205	207	28282.46	Online	2025-10-05 14:48:35.805126+05:30	\N
206	208	108685.55	Cash	2025-10-05 14:48:35.805126+05:30	\N
207	208	16848.81	Online	2025-10-05 14:48:35.805126+05:30	\N
208	209	94089.60	Card	2025-10-05 14:48:35.805126+05:30	\N
209	210	154000.00	Card	2025-10-05 14:48:35.805126+05:30	\N
210	211	82710.66	Cash	2025-10-05 14:48:35.805126+05:30	\N
211	212	79200.00	Card	2025-10-05 14:48:35.805126+05:30	\N
212	213	106920.00	Card	2025-10-05 14:48:35.805126+05:30	\N
213	214	11155.79	Cash	2025-10-05 14:48:35.805126+05:30	\N
214	214	6223.89	Online	2025-10-05 14:48:35.805126+05:30	\N
215	215	69652.00	Card	2025-10-05 14:48:35.805126+05:30	\N
216	216	55440.00	Card	2025-10-05 14:48:35.805126+05:30	\N
217	217	112856.27	Cash	2025-10-05 14:48:35.805126+05:30	\N
218	217	33179.73	Online	2025-10-05 14:48:35.805126+05:30	\N
219	218	125400.00	Card	2025-10-05 14:48:35.805126+05:30	\N
220	219	58594.80	Card	2025-10-05 14:48:35.805126+05:30	\N
221	220	20361.77	Cash	2025-10-05 14:48:35.805126+05:30	\N
222	221	89734.31	Cash	2025-10-05 14:48:35.805126+05:30	\N
223	222	157740.00	Card	2025-10-05 14:48:35.805126+05:30	\N
224	223	44662.99	Cash	2025-10-05 14:48:35.805126+05:30	\N
225	223	14098.63	Online	2025-10-05 14:48:35.805126+05:30	\N
226	226	130039.48	Cash	2025-10-05 14:48:35.805126+05:30	\N
227	226	24630.22	Online	2025-10-05 14:48:35.805126+05:30	\N
228	227	141240.00	Card	2025-10-05 14:48:35.805126+05:30	\N
229	228	143000.00	Card	2025-10-05 14:48:35.805126+05:30	\N
230	230	56760.00	Card	2025-10-05 14:48:35.805126+05:30	\N
231	231	55391.42	Cash	2025-10-05 14:48:35.805126+05:30	\N
232	231	58480.48	Online	2025-10-05 14:48:35.805126+05:30	\N
233	232	14511.24	Cash	2025-10-05 14:48:35.805126+05:30	\N
234	232	6546.92	Online	2025-10-05 14:48:35.805126+05:30	\N
235	233	118967.20	Card	2025-10-05 14:48:35.805126+05:30	\N
236	234	44110.09	Cash	2025-10-05 14:48:35.805126+05:30	\N
237	235	56535.64	Cash	2025-10-05 14:48:35.805126+05:30	\N
238	237	74295.51	Cash	2025-10-05 14:48:35.805126+05:30	\N
239	237	14913.66	Online	2025-10-05 14:48:35.805126+05:30	\N
240	238	99000.00	Card	2025-10-05 14:48:35.805126+05:30	\N
241	240	39600.00	Card	2025-10-05 14:48:35.805126+05:30	\N
242	241	99000.00	Card	2025-10-05 14:48:35.805126+05:30	\N
243	242	85536.00	Card	2025-10-05 14:48:35.805126+05:30	\N
244	243	59400.00	Card	2025-10-05 14:48:35.805126+05:30	\N
245	244	150347.08	Cash	2025-10-05 14:48:35.805126+05:30	\N
246	245	45786.37	Cash	2025-10-05 14:48:35.805126+05:30	\N
247	247	105403.45	Cash	2025-10-05 14:48:35.805126+05:30	\N
248	247	51367.35	Online	2025-10-05 14:48:35.805126+05:30	\N
249	248	24323.01	Cash	2025-10-05 14:48:35.805126+05:30	\N
250	248	14851.37	Online	2025-10-05 14:48:35.805126+05:30	\N
251	249	52140.00	Card	2025-10-05 14:48:35.805126+05:30	\N
252	250	82262.40	Card	2025-10-05 14:48:35.805126+05:30	\N
253	251	132330.00	Card	2025-10-05 14:48:35.805126+05:30	\N
254	252	78437.21	Cash	2025-10-05 14:48:35.805126+05:30	\N
255	253	37623.23	Cash	2025-10-05 14:48:35.805126+05:30	\N
256	254	102339.60	Card	2025-10-05 14:48:35.805126+05:30	\N
257	255	103567.20	Card	2025-10-05 14:48:35.805126+05:30	\N
258	257	67320.00	Card	2025-10-05 14:48:35.805126+05:30	\N
259	258	151417.20	Card	2025-10-05 14:48:35.805126+05:30	\N
260	259	54009.10	Cash	2025-10-05 14:48:35.805126+05:30	\N
261	259	14419.78	Online	2025-10-05 14:48:35.805126+05:30	\N
262	260	111870.00	Card	2025-10-05 14:48:35.805126+05:30	\N
263	261	32282.28	Cash	2025-10-05 14:48:35.805126+05:30	\N
264	261	11324.43	Online	2025-10-05 14:48:35.805126+05:30	\N
265	262	63102.99	Cash	2025-10-05 14:48:35.805126+05:30	\N
266	262	43771.45	Online	2025-10-05 14:48:35.805126+05:30	\N
267	264	157740.00	Card	2025-10-05 14:48:35.805126+05:30	\N
268	265	35776.31	Cash	2025-10-05 14:48:35.805126+05:30	\N
269	266	84810.00	Card	2025-10-05 14:48:35.805126+05:30	\N
270	267	62631.87	Cash	2025-10-05 14:48:35.805126+05:30	\N
271	267	15727.23	Online	2025-10-05 14:48:35.805126+05:30	\N
272	268	189420.00	Card	2025-10-05 14:48:35.805126+05:30	\N
273	269	56095.84	Cash	2025-10-05 14:48:35.805126+05:30	\N
274	270	70567.20	Card	2025-10-05 14:48:35.805126+05:30	\N
275	271	84810.00	Card	2025-10-05 14:48:35.805126+05:30	\N
276	272	78114.91	Cash	2025-10-05 14:48:35.805126+05:30	\N
277	272	24554.69	Online	2025-10-05 14:48:35.805126+05:30	\N
278	273	64020.00	Card	2025-10-05 14:48:35.805126+05:30	\N
279	274	44565.87	Cash	2025-10-05 14:48:35.805126+05:30	\N
280	274	37624.21	Online	2025-10-05 14:48:35.805126+05:30	\N
281	275	110440.00	Card	2025-10-05 14:48:35.805126+05:30	\N
282	276	51368.00	Cash	2025-10-05 14:48:35.805126+05:30	\N
283	276	16105.14	Online	2025-10-05 14:48:35.805126+05:30	\N
284	277	57564.77	Cash	2025-10-05 14:48:35.805126+05:30	\N
285	277	13031.29	Online	2025-10-05 14:48:35.805126+05:30	\N
286	278	50894.80	Card	2025-10-05 14:48:35.805126+05:30	\N
287	279	59082.34	Cash	2025-10-05 14:48:35.805126+05:30	\N
288	280	127529.60	Card	2025-10-05 14:48:35.805126+05:30	\N
289	281	155320.00	Card	2025-10-05 14:48:35.805126+05:30	\N
290	282	43560.00	Card	2025-10-05 14:48:35.805126+05:30	\N
291	283	56061.05	Cash	2025-10-05 14:48:35.805126+05:30	\N
292	284	107470.00	Card	2025-10-05 14:48:35.805126+05:30	\N
293	285	110643.45	Cash	2025-10-05 14:48:35.805126+05:30	\N
294	285	45996.55	Online	2025-10-05 14:48:35.805126+05:30	\N
295	286	45127.23	Cash	2025-10-05 14:48:35.805126+05:30	\N
296	287	43459.75	Cash	2025-10-05 14:48:35.805126+05:30	\N
297	288	50226.16	Cash	2025-10-05 14:48:35.805126+05:30	\N
298	289	33000.00	Card	2025-10-05 14:48:35.805126+05:30	\N
299	290	46254.49	Cash	2025-10-05 14:48:35.805126+05:30	\N
300	290	16579.56	Online	2025-10-05 14:48:35.805126+05:30	\N
301	291	33975.87	Cash	2025-10-05 14:48:35.805126+05:30	\N
302	292	133870.00	Card	2025-10-05 14:48:35.805126+05:30	\N
303	293	104447.20	Card	2025-10-05 14:48:35.805126+05:30	\N
304	294	87120.00	Card	2025-10-05 14:48:35.805126+05:30	\N
305	296	84097.20	Card	2025-10-05 14:48:35.805126+05:30	\N
306	297	53111.17	Cash	2025-10-05 14:48:35.805126+05:30	\N
307	297	35770.89	Online	2025-10-05 14:48:35.805126+05:30	\N
308	298	22099.29	Cash	2025-10-05 14:48:35.805126+05:30	\N
309	298	20801.51	Online	2025-10-05 14:48:35.805126+05:30	\N
310	299	49830.00	Card	2025-10-05 14:48:35.805126+05:30	\N
311	301	43560.00	Card	2025-10-05 14:48:35.805126+05:30	\N
312	302	32309.66	Cash	2025-10-05 14:48:35.805126+05:30	\N
313	303	116270.00	Card	2025-10-05 14:48:35.805126+05:30	\N
314	304	83142.65	Cash	2025-10-05 14:48:35.805126+05:30	\N
315	306	24182.40	Card	2025-10-05 14:48:35.805126+05:30	\N
316	307	80740.00	Card	2025-10-05 14:48:35.805126+05:30	\N
317	308	125400.00	Card	2025-10-05 14:48:35.805126+05:30	\N
318	309	52816.30	Cash	2025-10-05 14:48:35.805126+05:30	\N
319	309	19520.46	Online	2025-10-05 14:48:35.805126+05:30	\N
320	310	105336.00	Card	2025-10-05 14:48:35.805126+05:30	\N
321	311	44363.14	Cash	2025-10-05 14:48:35.805126+05:30	\N
322	311	26202.50	Online	2025-10-05 14:48:35.805126+05:30	\N
323	312	97630.22	Cash	2025-10-05 14:48:35.805126+05:30	\N
324	312	35684.91	Online	2025-10-05 14:48:35.805126+05:30	\N
325	313	148500.00	Card	2025-10-05 14:48:35.805126+05:30	\N
326	314	125400.00	Card	2025-10-05 14:48:35.805126+05:30	\N
327	315	75195.73	Cash	2025-10-05 14:48:35.805126+05:30	\N
328	316	80109.94	Cash	2025-10-05 14:48:35.805126+05:30	\N
329	316	15897.91	Online	2025-10-05 14:48:35.805126+05:30	\N
330	317	130020.00	Card	2025-10-05 14:48:35.805126+05:30	\N
331	318	74899.89	Cash	2025-10-05 14:48:35.805126+05:30	\N
332	318	26410.11	Online	2025-10-05 14:48:35.805126+05:30	\N
333	319	50933.81	Cash	2025-10-05 14:48:35.805126+05:30	\N
334	320	127380.00	Card	2025-10-05 14:48:35.805126+05:30	\N
335	321	106920.00	Card	2025-10-05 14:48:35.805126+05:30	\N
336	322	182089.60	Card	2025-10-05 14:48:35.805126+05:30	\N
337	323	110827.20	Card	2025-10-05 14:48:35.805126+05:30	\N
338	324	27891.74	Cash	2025-10-05 14:48:35.805126+05:30	\N
339	326	136620.00	Card	2025-10-05 14:48:35.805126+05:30	\N
340	327	49877.46	Cash	2025-10-05 14:48:35.805126+05:30	\N
341	328	74250.00	Card	2025-10-05 14:48:35.805126+05:30	\N
342	329	96536.00	Card	2025-10-05 14:48:35.805126+05:30	\N
343	330	76820.33	Cash	2025-10-05 14:48:35.805126+05:30	\N
344	332	97042.00	Card	2025-10-05 14:48:35.805126+05:30	\N
345	333	39863.03	Cash	2025-10-05 14:48:35.805126+05:30	\N
346	334	80388.00	Card	2025-10-05 14:48:35.805126+05:30	\N
347	335	23635.08	Cash	2025-10-05 14:48:35.805126+05:30	\N
348	336	107619.60	Card	2025-10-05 14:48:35.805126+05:30	\N
349	337	135300.00	Card	2025-10-05 14:48:35.805126+05:30	\N
350	338	108757.08	Cash	2025-10-05 14:48:35.805126+05:30	\N
351	339	59730.00	Card	2025-10-05 14:48:35.805126+05:30	\N
352	340	70348.52	Cash	2025-10-05 14:48:35.805126+05:30	\N
353	340	19411.48	Online	2025-10-05 14:48:35.805126+05:30	\N
354	342	69062.40	Card	2025-10-05 14:48:35.805126+05:30	\N
355	343	84810.00	Card	2025-10-05 14:48:35.805126+05:30	\N
356	344	96910.00	Card	2025-10-05 14:48:35.805126+05:30	\N
357	346	62269.05	Cash	2025-10-05 14:48:35.805126+05:30	\N
358	346	29418.15	Online	2025-10-05 14:48:35.805126+05:30	\N
359	347	68790.07	Cash	2025-10-05 14:48:35.805126+05:30	\N
360	348	51810.00	Card	2025-10-05 14:48:35.805126+05:30	\N
361	349	73260.00	Card	2025-10-05 14:48:35.805126+05:30	\N
362	350	27862.02	Cash	2025-10-05 14:48:35.805126+05:30	\N
363	351	95810.00	Card	2025-10-05 14:48:35.805126+05:30	\N
364	352	89284.80	Card	2025-10-05 14:48:35.805126+05:30	\N
365	353	78540.00	Card	2025-10-05 14:48:35.805126+05:30	\N
366	354	80300.00	Card	2025-10-05 14:48:35.805126+05:30	\N
367	355	40048.11	Cash	2025-10-05 14:48:35.805126+05:30	\N
368	355	34655.42	Online	2025-10-05 14:48:35.805126+05:30	\N
369	356	71720.00	Card	2025-10-05 14:48:35.805126+05:30	\N
370	357	41052.00	Card	2025-10-05 14:48:35.805126+05:30	\N
371	358	66000.00	Card	2025-10-05 14:48:35.805126+05:30	\N
372	359	22639.56	Cash	2025-10-05 14:48:35.805126+05:30	\N
373	360	55398.54	Cash	2025-10-05 14:48:35.805126+05:30	\N
374	362	39600.00	Card	2025-10-05 14:48:35.805126+05:30	\N
375	363	17383.87	Cash	2025-10-05 14:48:35.805126+05:30	\N
376	364	22059.80	Cash	2025-10-05 14:48:35.805126+05:30	\N
377	365	83930.00	Card	2025-10-05 14:48:35.805126+05:30	\N
378	366	31598.23	Cash	2025-10-05 14:48:35.805126+05:30	\N
379	367	19127.63	Cash	2025-10-05 14:48:35.805126+05:30	\N
380	368	70476.14	Cash	2025-10-05 14:48:35.805126+05:30	\N
381	369	95150.00	Card	2025-10-05 14:48:35.805126+05:30	\N
382	370	46240.12	Cash	2025-10-05 14:48:35.805126+05:30	\N
383	370	11839.88	Online	2025-10-05 14:48:35.805126+05:30	\N
384	371	100663.20	Card	2025-10-05 14:48:35.805126+05:30	\N
385	372	12567.98	Cash	2025-10-05 14:48:35.805126+05:30	\N
386	373	41690.70	Cash	2025-10-05 14:48:35.805126+05:30	\N
387	374	7429.19	Cash	2025-10-05 14:48:35.805126+05:30	\N
388	375	51810.00	Card	2025-10-05 14:48:35.805126+05:30	\N
389	376	41026.75	Cash	2025-10-05 14:48:35.805126+05:30	\N
390	376	13533.25	Online	2025-10-05 14:48:35.805126+05:30	\N
391	377	44880.00	Card	2025-10-05 14:48:35.805126+05:30	\N
392	378	29153.89	Cash	2025-10-05 14:48:35.805126+05:30	\N
393	379	32340.00	Card	2025-10-05 14:48:35.805126+05:30	\N
394	380	14256.00	Card	2025-10-05 14:48:35.805126+05:30	\N
395	382	18643.63	Cash	2025-10-05 14:48:35.805126+05:30	\N
396	383	27402.14	Cash	2025-10-05 14:48:35.805126+05:30	\N
397	385	64900.00	Card	2025-10-05 14:48:35.805126+05:30	\N
398	386	92400.00	Card	2025-10-05 14:48:35.805126+05:30	\N
399	387	66000.00	Card	2025-10-05 14:48:35.805126+05:30	\N
400	389	83693.01	Cash	2025-10-05 14:48:35.805126+05:30	\N
401	390	50840.84	Cash	2025-10-05 14:48:35.805126+05:30	\N
402	391	73345.12	Cash	2025-10-05 14:48:35.805126+05:30	\N
403	391	23665.05	Online	2025-10-05 14:48:35.805126+05:30	\N
404	392	84480.00	Card	2025-10-05 14:48:35.805126+05:30	\N
405	393	102876.40	Card	2025-10-05 14:48:35.805126+05:30	\N
406	394	130130.00	Card	2025-10-05 14:48:35.805126+05:30	\N
407	395	123310.00	Card	2025-10-05 14:48:35.805126+05:30	\N
408	396	15681.60	Card	2025-10-05 14:48:35.805126+05:30	\N
409	397	62040.00	Card	2025-10-05 14:48:35.805126+05:30	\N
410	398	27786.53	Cash	2025-10-05 14:48:35.805126+05:30	\N
411	398	13612.58	Online	2025-10-05 14:48:35.805126+05:30	\N
412	399	112750.00	Card	2025-10-05 14:48:35.805126+05:30	\N
413	401	35721.72	Cash	2025-10-05 14:48:35.805126+05:30	\N
414	401	24068.81	Online	2025-10-05 14:48:35.805126+05:30	\N
415	402	98582.00	Card	2025-10-05 14:48:35.805126+05:30	\N
416	403	14808.86	Cash	2025-10-05 14:48:35.805126+05:30	\N
417	403	2803.48	Online	2025-10-05 14:48:35.805126+05:30	\N
418	404	31900.00	Card	2025-10-05 14:48:35.805126+05:30	\N
419	406	125400.00	Card	2025-10-05 14:48:35.805126+05:30	\N
420	407	57024.00	Card	2025-10-05 14:48:35.805126+05:30	\N
421	408	110880.00	Card	2025-10-05 14:48:35.805126+05:30	\N
422	409	38246.81	Cash	2025-10-05 14:48:35.805126+05:30	\N
423	409	11759.13	Online	2025-10-05 14:48:35.805126+05:30	\N
424	410	98340.00	Card	2025-10-05 14:48:35.805126+05:30	\N
425	411	65890.00	Card	2025-10-05 14:48:35.805126+05:30	\N
426	412	88240.38	Cash	2025-10-05 14:48:35.805126+05:30	\N
427	412	29266.02	Online	2025-10-05 14:48:35.805126+05:30	\N
428	413	11550.56	Cash	2025-10-05 14:48:35.805126+05:30	\N
429	413	3629.44	Online	2025-10-05 14:48:35.805126+05:30	\N
430	414	91608.00	Card	2025-10-05 14:48:35.805126+05:30	\N
431	416	38060.00	Card	2025-10-05 14:48:35.805126+05:30	\N
432	417	92840.00	Card	2025-10-05 14:48:35.805126+05:30	\N
433	418	54120.00	Card	2025-10-05 14:48:35.805126+05:30	\N
434	419	53648.62	Cash	2025-10-05 14:48:35.805126+05:30	\N
435	419	8215.61	Online	2025-10-05 14:48:35.805126+05:30	\N
436	420	27231.60	Card	2025-10-05 14:48:35.805126+05:30	\N
437	421	102388.00	Card	2025-10-05 14:48:35.805126+05:30	\N
438	422	48523.20	Card	2025-10-05 14:48:35.805126+05:30	\N
439	425	25080.00	Card	2025-10-05 14:48:35.805126+05:30	\N
440	427	15387.04	Cash	2025-10-05 14:48:35.805126+05:30	\N
441	427	11172.16	Online	2025-10-05 14:48:35.805126+05:30	\N
442	429	109164.00	Card	2025-10-05 14:48:35.805126+05:30	\N
443	430	72600.00	Card	2025-10-05 14:48:35.805126+05:30	\N
444	431	34100.00	Card	2025-10-05 14:48:35.805126+05:30	\N
445	432	41103.08	Cash	2025-10-05 14:48:35.805126+05:30	\N
446	432	22945.64	Online	2025-10-05 14:48:35.805126+05:30	\N
447	433	82526.40	Card	2025-10-05 14:48:35.805126+05:30	\N
448	435	76428.89	Cash	2025-10-05 14:48:35.805126+05:30	\N
449	436	12376.02	Cash	2025-10-05 14:48:35.805126+05:30	\N
450	437	10178.59	Cash	2025-10-05 14:48:35.805126+05:30	\N
451	438	90860.00	Card	2025-10-05 14:48:35.805126+05:30	\N
452	440	38820.83	Cash	2025-10-05 14:48:35.805126+05:30	\N
453	440	24027.58	Online	2025-10-05 14:48:35.805126+05:30	\N
454	441	35835.25	Cash	2025-10-05 14:48:35.805126+05:30	\N
455	442	78408.00	Card	2025-10-05 14:48:35.805126+05:30	\N
456	443	31363.20	Card	2025-10-05 14:48:35.805126+05:30	\N
457	444	58080.00	Card	2025-10-05 14:48:35.805126+05:30	\N
458	445	96897.21	Cash	2025-10-05 14:48:35.805126+05:30	\N
459	447	14620.24	Cash	2025-10-05 14:48:35.805126+05:30	\N
460	448	99000.00	Card	2025-10-05 14:48:35.805126+05:30	\N
461	449	29040.00	Card	2025-10-05 14:48:35.805126+05:30	\N
462	451	56518.00	Card	2025-10-05 14:48:35.805126+05:30	\N
463	452	44817.85	Cash	2025-10-05 14:48:35.805126+05:30	\N
464	452	12471.79	Online	2025-10-05 14:48:35.805126+05:30	\N
465	453	44352.00	Card	2025-10-05 14:48:35.805126+05:30	\N
466	454	56357.81	Cash	2025-10-05 14:48:35.805126+05:30	\N
467	454	32906.32	Online	2025-10-05 14:48:35.805126+05:30	\N
468	455	88330.00	Card	2025-10-05 14:48:35.805126+05:30	\N
469	456	69960.00	Card	2025-10-05 14:48:35.805126+05:30	\N
470	457	47617.00	Cash	2025-10-05 14:48:35.805126+05:30	\N
471	457	14796.86	Online	2025-10-05 14:48:35.805126+05:30	\N
472	458	25448.79	Cash	2025-10-05 14:48:35.805126+05:30	\N
473	459	90226.40	Card	2025-10-05 14:48:35.805126+05:30	\N
474	460	40590.00	Card	2025-10-05 14:48:35.805126+05:30	\N
475	461	29040.00	Card	2025-10-05 14:48:35.805126+05:30	\N
476	462	15667.99	Cash	2025-10-05 14:48:35.805126+05:30	\N
477	463	84727.73	Cash	2025-10-05 14:48:35.805126+05:30	\N
478	463	33522.27	Online	2025-10-05 14:48:35.805126+05:30	\N
479	465	62541.10	Cash	2025-10-05 14:48:35.805126+05:30	\N
480	466	76586.40	Card	2025-10-05 14:48:35.805126+05:30	\N
481	467	60403.20	Card	2025-10-05 14:48:35.805126+05:30	\N
482	468	18480.00	Card	2025-10-05 14:48:35.805126+05:30	\N
483	469	127710.00	Card	2025-10-05 14:48:35.805126+05:30	\N
484	470	64680.00	Card	2025-10-05 14:48:35.805126+05:30	\N
485	472	44550.00	Card	2025-10-05 14:48:35.805126+05:30	\N
486	473	133980.00	Card	2025-10-05 14:48:35.805126+05:30	\N
487	474	260150.00	Card	2025-10-05 14:48:35.805126+05:30	\N
488	476	88000.00	Card	2025-10-05 14:48:35.805126+05:30	\N
489	477	33857.25	Cash	2025-10-05 14:48:35.805126+05:30	\N
490	477	19029.38	Online	2025-10-05 14:48:35.805126+05:30	\N
491	478	148203.10	Cash	2025-10-05 14:48:35.805126+05:30	\N
492	478	49961.16	Online	2025-10-05 14:48:35.805126+05:30	\N
493	479	97172.07	Cash	2025-10-05 14:48:35.805126+05:30	\N
494	480	89320.00	Card	2025-10-05 14:48:35.805126+05:30	\N
495	481	156816.00	Card	2025-10-05 14:48:35.805126+05:30	\N
496	482	78170.78	Cash	2025-10-05 14:48:35.805126+05:30	\N
497	483	226600.00	Card	2025-10-05 14:48:35.805126+05:30	\N
498	485	342760.00	Card	2025-10-05 14:48:35.805126+05:30	\N
499	486	129239.69	Cash	2025-10-05 14:48:35.805126+05:30	\N
500	486	39786.31	Online	2025-10-05 14:48:35.805126+05:30	\N
501	487	172865.22	Cash	2025-10-05 14:48:35.805126+05:30	\N
502	487	32684.25	Online	2025-10-05 14:48:35.805126+05:30	\N
503	489	137800.22	Cash	2025-10-05 14:48:35.805126+05:30	\N
504	489	37055.78	Online	2025-10-05 14:48:35.805126+05:30	\N
505	490	163680.00	Card	2025-10-05 14:48:35.805126+05:30	\N
506	491	55712.22	Cash	2025-10-05 14:48:35.805126+05:30	\N
507	491	17368.05	Online	2025-10-05 14:48:35.805126+05:30	\N
508	492	158840.00	Card	2025-10-05 14:48:35.805126+05:30	\N
509	493	127827.93	Cash	2025-10-05 14:48:35.805126+05:30	\N
510	494	151800.00	Card	2025-10-05 14:48:35.805126+05:30	\N
511	495	186576.67	Cash	2025-10-05 14:48:35.805126+05:30	\N
512	496	229460.00	Card	2025-10-05 14:48:35.805126+05:30	\N
513	497	143000.00	Card	2025-10-05 14:48:35.805126+05:30	\N
514	499	67311.83	Cash	2025-10-05 14:48:35.805126+05:30	\N
515	499	30478.46	Online	2025-10-05 14:48:35.805126+05:30	\N
516	501	129580.00	Card	2025-10-05 14:48:35.805126+05:30	\N
517	503	206800.00	Card	2025-10-05 14:48:35.805126+05:30	\N
518	504	101454.18	Cash	2025-10-05 14:48:35.805126+05:30	\N
519	505	123574.00	Card	2025-10-05 14:48:35.805126+05:30	\N
520	507	210540.00	Card	2025-10-05 14:48:35.805126+05:30	\N
521	508	140844.00	Card	2025-10-05 14:48:35.805126+05:30	\N
522	509	122531.92	Cash	2025-10-05 14:48:35.805126+05:30	\N
523	510	48400.00	Card	2025-10-05 14:48:35.805126+05:30	\N
524	512	125994.00	Card	2025-10-05 14:48:35.805126+05:30	\N
525	513	75231.93	Cash	2025-10-05 14:48:35.805126+05:30	\N
526	514	45900.87	Cash	2025-10-05 14:48:35.805126+05:30	\N
527	514	40282.28	Online	2025-10-05 14:48:35.805126+05:30	\N
528	515	116600.00	Card	2025-10-05 14:48:35.805126+05:30	\N
529	517	220000.00	Card	2025-10-05 14:48:35.805126+05:30	\N
530	518	88000.00	Card	2025-10-05 14:48:35.805126+05:30	\N
531	519	30996.48	Cash	2025-10-05 14:48:35.805126+05:30	\N
532	520	204930.00	Card	2025-10-05 14:48:35.805126+05:30	\N
533	522	94820.00	Card	2025-10-05 14:48:35.805126+05:30	\N
534	523	148399.65	Cash	2025-10-05 14:48:35.805126+05:30	\N
535	523	55254.14	Online	2025-10-05 14:48:35.805126+05:30	\N
536	524	147950.00	Card	2025-10-05 14:48:35.805126+05:30	\N
537	525	49706.01	Cash	2025-10-05 14:48:35.805126+05:30	\N
538	525	17599.93	Online	2025-10-05 14:48:35.805126+05:30	\N
539	527	215688.00	Card	2025-10-05 14:48:35.805126+05:30	\N
540	528	170016.00	Card	2025-10-05 14:48:35.805126+05:30	\N
541	529	136400.00	Card	2025-10-05 14:48:35.805126+05:30	\N
542	530	160666.00	Card	2025-10-05 14:48:35.805126+05:30	\N
543	531	57921.78	Cash	2025-10-05 14:48:35.805126+05:30	\N
544	531	36054.08	Online	2025-10-05 14:48:35.805126+05:30	\N
545	532	194507.29	Cash	2025-10-05 14:48:35.805126+05:30	\N
546	533	193600.00	Card	2025-10-05 14:48:35.805126+05:30	\N
547	534	109269.97	Cash	2025-10-05 14:48:35.805126+05:30	\N
548	534	43336.64	Online	2025-10-05 14:48:35.805126+05:30	\N
549	535	146828.27	Cash	2025-10-05 14:48:35.805126+05:30	\N
550	536	129800.00	Card	2025-10-05 14:48:35.805126+05:30	\N
551	537	284900.00	Card	2025-10-05 14:48:35.805126+05:30	\N
552	538	59477.60	Cash	2025-10-05 14:48:35.805126+05:30	\N
553	538	12514.30	Online	2025-10-05 14:48:35.805126+05:30	\N
554	539	83205.71	Cash	2025-10-05 14:48:35.805126+05:30	\N
555	539	49603.15	Online	2025-10-05 14:48:35.805126+05:30	\N
556	540	110000.00	Card	2025-10-05 14:48:35.805126+05:30	\N
557	541	170544.00	Card	2025-10-05 14:48:35.805126+05:30	\N
558	542	276760.00	Card	2025-10-05 14:48:35.805126+05:30	\N
559	543	83160.00	Card	2025-10-05 14:48:35.805126+05:30	\N
560	544	41636.92	Cash	2025-10-05 14:48:35.805126+05:30	\N
561	544	7928.08	Online	2025-10-05 14:48:35.805126+05:30	\N
562	545	11291.56	Cash	2025-10-05 14:48:35.805126+05:30	\N
563	545	13173.25	Online	2025-10-05 14:48:35.805126+05:30	\N
564	546	65328.81	Cash	2025-10-05 14:48:35.805126+05:30	\N
565	546	46810.98	Online	2025-10-05 14:48:35.805126+05:30	\N
566	547	80630.00	Card	2025-10-05 14:48:35.805126+05:30	\N
567	548	37400.00	Card	2025-10-05 14:48:35.805126+05:30	\N
568	549	82852.00	Card	2025-10-05 14:48:35.805126+05:30	\N
569	551	56760.00	Card	2025-10-05 14:48:35.805126+05:30	\N
570	552	48674.20	Cash	2025-10-05 14:48:35.805126+05:30	\N
571	553	131282.80	Card	2025-10-05 14:48:35.805126+05:30	\N
572	554	58300.00	Card	2025-10-05 14:48:35.805126+05:30	\N
573	555	98670.00	Card	2025-10-05 14:48:35.805126+05:30	\N
574	557	120010.00	Card	2025-10-05 14:48:35.805126+05:30	\N
575	558	85140.00	Card	2025-10-05 14:48:35.805126+05:30	\N
576	559	58080.00	Card	2025-10-05 14:48:35.805126+05:30	\N
577	560	79168.19	Cash	2025-10-05 14:48:35.805126+05:30	\N
578	561	98670.00	Card	2025-10-05 14:48:35.805126+05:30	\N
579	562	172752.80	Card	2025-10-05 14:48:35.805126+05:30	\N
580	565	164076.00	Card	2025-10-05 14:48:35.805126+05:30	\N
581	566	73363.68	Cash	2025-10-05 14:48:35.805126+05:30	\N
582	566	9317.89	Online	2025-10-05 14:48:35.805126+05:30	\N
583	567	37060.09	Cash	2025-10-05 14:48:35.805126+05:30	\N
584	568	102936.93	Cash	2025-10-05 14:48:35.805126+05:30	\N
585	568	44793.61	Online	2025-10-05 14:48:35.805126+05:30	\N
586	569	165330.00	Card	2025-10-05 14:48:35.805126+05:30	\N
587	570	61171.98	Cash	2025-10-05 14:48:35.805126+05:30	\N
588	570	13390.20	Online	2025-10-05 14:48:35.805126+05:30	\N
589	571	65010.00	Card	2025-10-05 14:48:35.805126+05:30	\N
590	572	92444.00	Card	2025-10-05 14:48:35.805126+05:30	\N
591	573	113300.00	Card	2025-10-05 14:48:35.805126+05:30	\N
592	575	87095.40	Cash	2025-10-05 14:48:35.805126+05:30	\N
593	575	26424.60	Online	2025-10-05 14:48:35.805126+05:30	\N
594	576	155760.00	Card	2025-10-05 14:48:35.805126+05:30	\N
595	577	115526.40	Card	2025-10-05 14:48:35.805126+05:30	\N
596	578	33002.67	Cash	2025-10-05 14:48:35.805126+05:30	\N
597	579	102537.38	Cash	2025-10-05 14:48:35.805126+05:30	\N
598	579	47662.47	Online	2025-10-05 14:48:35.805126+05:30	\N
599	583	105380.00	Card	2025-10-05 14:48:35.805126+05:30	\N
600	584	110564.62	Cash	2025-10-05 14:48:35.805126+05:30	\N
601	584	44588.18	Online	2025-10-05 14:48:35.805126+05:30	\N
602	585	145200.00	Card	2025-10-05 14:48:35.805126+05:30	\N
603	587	96470.00	Card	2025-10-05 14:48:35.805126+05:30	\N
604	588	124106.40	Card	2025-10-05 14:48:35.805126+05:30	\N
605	589	188760.00	Card	2025-10-05 14:48:35.805126+05:30	\N
606	590	24590.55	Cash	2025-10-05 14:48:35.805126+05:30	\N
607	592	49014.67	Cash	2025-10-05 14:48:35.805126+05:30	\N
608	592	17357.85	Online	2025-10-05 14:48:35.805126+05:30	\N
609	593	51009.12	Cash	2025-10-05 14:48:35.805126+05:30	\N
610	593	48856.08	Online	2025-10-05 14:48:35.805126+05:30	\N
611	595	227040.00	Card	2025-10-05 14:48:35.805126+05:30	\N
612	596	105600.00	Card	2025-10-05 14:48:35.805126+05:30	\N
613	597	93390.00	Card	2025-10-05 14:48:35.805126+05:30	\N
614	600	139642.80	Card	2025-10-05 14:48:35.805126+05:30	\N
615	601	187110.00	Card	2025-10-05 14:48:35.805126+05:30	\N
616	602	189860.00	Card	2025-10-05 14:48:35.805126+05:30	\N
617	604	33281.80	Cash	2025-10-05 14:48:35.805126+05:30	\N
618	605	18600.83	Cash	2025-10-05 14:48:35.805126+05:30	\N
619	605	9044.69	Online	2025-10-05 14:48:35.805126+05:30	\N
620	606	85093.66	Cash	2025-10-05 14:48:35.805126+05:30	\N
621	607	137720.00	Card	2025-10-05 14:48:35.805126+05:30	\N
622	608	78126.40	Card	2025-10-05 14:48:35.805126+05:30	\N
623	609	29843.34	Cash	2025-10-05 14:48:35.805126+05:30	\N
624	609	15337.76	Online	2025-10-05 14:48:35.805126+05:30	\N
625	610	88123.20	Card	2025-10-05 14:48:35.805126+05:30	\N
626	611	111122.49	Cash	2025-10-05 14:48:35.805126+05:30	\N
627	611	51242.05	Online	2025-10-05 14:48:35.805126+05:30	\N
628	612	143589.60	Card	2025-10-05 14:48:35.805126+05:30	\N
629	614	137940.00	Card	2025-10-05 14:48:35.805126+05:30	\N
630	615	105049.31	Cash	2025-10-05 14:48:35.805126+05:30	\N
631	615	35200.69	Online	2025-10-05 14:48:35.805126+05:30	\N
632	616	172920.00	Card	2025-10-05 14:48:35.805126+05:30	\N
633	617	149776.00	Card	2025-10-05 14:48:35.805126+05:30	\N
634	618	54120.00	Card	2025-10-05 14:48:35.805126+05:30	\N
635	619	24579.76	Cash	2025-10-05 14:48:35.805126+05:30	\N
636	619	12097.88	Online	2025-10-05 14:48:35.805126+05:30	\N
637	621	183700.00	Card	2025-10-05 14:48:35.805126+05:30	\N
638	622	108796.68	Cash	2025-10-05 14:48:35.805126+05:30	\N
639	622	24016.74	Online	2025-10-05 14:48:35.805126+05:30	\N
640	623	253616.00	Card	2025-10-05 14:48:35.805126+05:30	\N
641	624	52807.28	Cash	2025-10-05 14:48:35.805126+05:30	\N
642	624	19192.87	Online	2025-10-05 14:48:35.805126+05:30	\N
643	625	61930.00	Card	2025-10-05 14:48:35.805126+05:30	\N
644	626	33000.00	Card	2025-10-05 14:48:35.805126+05:30	\N
645	627	41949.00	Cash	2025-10-05 14:48:35.805126+05:30	\N
646	628	24324.34	Cash	2025-10-05 14:48:35.805126+05:30	\N
647	628	22837.41	Online	2025-10-05 14:48:35.805126+05:30	\N
648	629	163416.00	Card	2025-10-05 14:48:35.805126+05:30	\N
649	630	160710.00	Card	2025-10-05 14:48:35.805126+05:30	\N
650	631	23768.52	Cash	2025-10-05 14:48:35.805126+05:30	\N
651	631	17051.20	Online	2025-10-05 14:48:35.805126+05:30	\N
652	632	201960.00	Card	2025-10-05 14:48:35.805126+05:30	\N
653	633	108570.00	Card	2025-10-05 14:48:35.805126+05:30	\N
654	636	123186.77	Cash	2025-10-05 14:48:35.805126+05:30	\N
655	638	113262.11	Cash	2025-10-05 14:48:35.805126+05:30	\N
656	639	64102.56	Cash	2025-10-05 14:48:35.805126+05:30	\N
657	640	81463.06	Cash	2025-10-05 14:48:35.805126+05:30	\N
658	640	18605.67	Online	2025-10-05 14:48:35.805126+05:30	\N
659	641	61786.10	Cash	2025-10-05 14:48:35.805126+05:30	\N
660	641	40277.77	Online	2025-10-05 14:48:35.805126+05:30	\N
661	642	146664.33	Cash	2025-10-05 14:48:35.805126+05:30	\N
662	643	51882.09	Cash	2025-10-05 14:48:35.805126+05:30	\N
663	644	23523.43	Cash	2025-10-05 14:48:35.805126+05:30	\N
664	644	6445.24	Online	2025-10-05 14:48:35.805126+05:30	\N
665	645	34415.78	Cash	2025-10-05 14:48:35.805126+05:30	\N
666	646	48290.00	Card	2025-10-05 14:48:35.805126+05:30	\N
667	648	43454.66	Cash	2025-10-05 14:48:35.805126+05:30	\N
668	649	66445.29	Cash	2025-10-05 14:48:35.805126+05:30	\N
669	651	28840.89	Cash	2025-10-05 14:48:35.805126+05:30	\N
670	651	12983.79	Online	2025-10-05 14:48:35.805126+05:30	\N
671	653	98670.00	Card	2025-10-05 14:48:35.805126+05:30	\N
672	654	82433.48	Cash	2025-10-05 14:48:35.805126+05:30	\N
673	656	146009.60	Card	2025-10-05 14:48:35.805126+05:30	\N
674	657	72145.13	Cash	2025-10-05 14:48:35.805126+05:30	\N
675	658	76549.11	Cash	2025-10-05 14:48:35.805126+05:30	\N
676	658	38661.04	Online	2025-10-05 14:48:35.805126+05:30	\N
677	659	56876.77	Cash	2025-10-05 14:48:35.805126+05:30	\N
678	659	18115.73	Online	2025-10-05 14:48:35.805126+05:30	\N
679	660	119570.00	Card	2025-10-05 14:48:35.805126+05:30	\N
680	661	174240.00	Card	2025-10-05 14:48:35.805126+05:30	\N
681	662	113080.00	Card	2025-10-05 14:48:35.805126+05:30	\N
682	663	36582.35	Cash	2025-10-05 14:48:35.805126+05:30	\N
683	663	10496.59	Online	2025-10-05 14:48:35.805126+05:30	\N
684	664	77991.68	Cash	2025-10-05 14:48:35.805126+05:30	\N
685	664	20848.62	Online	2025-10-05 14:48:35.805126+05:30	\N
686	665	89892.00	Card	2025-10-05 14:48:35.805126+05:30	\N
687	666	31190.62	Cash	2025-10-05 14:48:35.805126+05:30	\N
688	667	93060.00	Card	2025-10-05 14:48:35.805126+05:30	\N
689	668	41580.00	Card	2025-10-05 14:48:35.805126+05:30	\N
690	669	21780.00	Card	2025-10-05 14:48:35.805126+05:30	\N
691	670	20698.16	Cash	2025-10-05 14:48:35.805126+05:30	\N
692	670	13189.41	Online	2025-10-05 14:48:35.805126+05:30	\N
693	671	30666.39	Cash	2025-10-05 14:48:35.805126+05:30	\N
694	672	34862.67	Cash	2025-10-05 14:48:35.805126+05:30	\N
695	672	8752.13	Online	2025-10-05 14:48:35.805126+05:30	\N
696	673	52565.96	Cash	2025-10-05 14:48:35.805126+05:30	\N
697	674	195360.00	Card	2025-10-05 14:48:35.805126+05:30	\N
698	675	101970.00	Card	2025-10-05 14:48:35.805126+05:30	\N
699	676	78540.00	Card	2025-10-05 14:48:35.805126+05:30	\N
700	677	173800.00	Card	2025-10-05 14:48:35.805126+05:30	\N
701	678	118140.00	Card	2025-10-05 14:48:35.805126+05:30	\N
702	680	109489.60	Card	2025-10-05 14:48:35.805126+05:30	\N
703	681	143000.00	Card	2025-10-05 14:48:35.805126+05:30	\N
704	682	55940.54	Cash	2025-10-05 14:48:35.805126+05:30	\N
705	682	26290.22	Online	2025-10-05 14:48:35.805126+05:30	\N
706	683	65340.00	Card	2025-10-05 14:48:35.805126+05:30	\N
707	684	48364.80	Card	2025-10-05 14:48:35.805126+05:30	\N
708	685	109890.00	Card	2025-10-05 14:48:35.805126+05:30	\N
709	686	41231.67	Cash	2025-10-05 14:48:35.805126+05:30	\N
710	686	22698.50	Online	2025-10-05 14:48:35.805126+05:30	\N
711	687	58960.00	Card	2025-10-05 14:48:35.805126+05:30	\N
712	688	96987.67	Cash	2025-10-05 14:48:35.805126+05:30	\N
713	689	142560.00	Card	2025-10-05 14:48:35.805126+05:30	\N
714	690	95700.00	Card	2025-10-05 14:48:35.805126+05:30	\N
715	691	83160.00	Card	2025-10-05 14:48:35.805126+05:30	\N
716	692	52595.01	Cash	2025-10-05 14:48:35.805126+05:30	\N
717	692	22581.23	Online	2025-10-05 14:48:35.805126+05:30	\N
718	693	64020.00	Card	2025-10-05 14:48:35.805126+05:30	\N
719	694	99000.00	Card	2025-10-05 14:48:35.805126+05:30	\N
720	695	174900.00	Card	2025-10-05 14:48:35.805126+05:30	\N
721	697	110167.20	Card	2025-10-05 14:48:35.805126+05:30	\N
722	698	58764.17	Cash	2025-10-05 14:48:35.805126+05:30	\N
723	699	64390.72	Cash	2025-10-05 14:48:35.805126+05:30	\N
724	699	29564.18	Online	2025-10-05 14:48:35.805126+05:30	\N
725	700	63297.53	Cash	2025-10-05 14:48:35.805126+05:30	\N
726	702	33603.99	Cash	2025-10-05 14:48:35.805126+05:30	\N
727	703	40770.41	Cash	2025-10-05 14:48:35.805126+05:30	\N
728	703	28992.60	Online	2025-10-05 14:48:35.805126+05:30	\N
729	704	100029.60	Card	2025-10-05 14:48:35.805126+05:30	\N
730	705	29883.80	Cash	2025-10-05 14:48:35.805126+05:30	\N
731	705	14493.32	Online	2025-10-05 14:48:35.805126+05:30	\N
732	706	174900.00	Card	2025-10-05 14:48:35.805126+05:30	\N
733	708	47300.00	Card	2025-10-05 14:48:35.805126+05:30	\N
734	709	36314.67	Cash	2025-10-05 14:48:35.805126+05:30	\N
735	709	14025.47	Online	2025-10-05 14:48:35.805126+05:30	\N
736	710	132000.00	Card	2025-10-05 14:48:35.805126+05:30	\N
737	712	79200.00	Card	2025-10-05 14:48:35.805126+05:30	\N
738	713	73164.46	Cash	2025-10-05 14:48:35.805126+05:30	\N
739	715	84150.00	Card	2025-10-05 14:48:35.805126+05:30	\N
740	717	73040.00	Card	2025-10-05 14:48:35.805126+05:30	\N
741	718	136567.20	Card	2025-10-05 14:48:35.805126+05:30	\N
742	719	57360.02	Cash	2025-10-05 14:48:35.805126+05:30	\N
743	720	87120.00	Card	2025-10-05 14:48:35.805126+05:30	\N
744	721	101420.00	Card	2025-10-05 14:48:35.805126+05:30	\N
745	722	55748.63	Cash	2025-10-05 14:48:35.805126+05:30	\N
746	723	126720.00	Card	2025-10-05 14:48:35.805126+05:30	\N
747	724	73590.00	Card	2025-10-05 14:48:35.805126+05:30	\N
748	725	160512.00	Card	2025-10-05 14:48:35.805126+05:30	\N
749	726	54072.60	Cash	2025-10-05 14:48:35.805126+05:30	\N
750	726	10309.51	Online	2025-10-05 14:48:35.805126+05:30	\N
751	727	53276.33	Cash	2025-10-05 14:48:35.805126+05:30	\N
752	728	110550.00	Card	2025-10-05 14:48:35.805126+05:30	\N
753	729	99000.00	Card	2025-10-05 14:48:35.805126+05:30	\N
754	730	47273.41	Cash	2025-10-05 14:48:35.805126+05:30	\N
755	732	30074.00	Card	2025-10-05 14:48:35.805126+05:30	\N
756	733	51546.52	Cash	2025-10-05 14:48:35.805126+05:30	\N
757	734	70092.00	Card	2025-10-05 14:48:35.805126+05:30	\N
758	735	32214.87	Cash	2025-10-05 14:48:35.805126+05:30	\N
759	736	59523.21	Cash	2025-10-05 14:48:35.805126+05:30	\N
760	736	31551.47	Online	2025-10-05 14:48:35.805126+05:30	\N
761	737	83930.00	Card	2025-10-05 14:48:35.805126+05:30	\N
762	738	28802.40	Card	2025-10-05 14:48:35.805126+05:30	\N
763	739	107140.00	Card	2025-10-05 14:48:35.805126+05:30	\N
764	741	40034.37	Cash	2025-10-05 14:48:35.805126+05:30	\N
765	742	49742.71	Cash	2025-10-05 14:48:35.805126+05:30	\N
766	742	30195.72	Online	2025-10-05 14:48:35.805126+05:30	\N
767	743	30157.49	Cash	2025-10-05 14:48:35.805126+05:30	\N
768	743	17360.04	Online	2025-10-05 14:48:35.805126+05:30	\N
769	744	102630.00	Card	2025-10-05 14:48:35.805126+05:30	\N
770	745	141240.00	Card	2025-10-05 14:48:35.805126+05:30	\N
771	746	99330.00	Card	2025-10-05 14:48:35.805126+05:30	\N
772	748	45431.54	Cash	2025-10-05 14:48:35.805126+05:30	\N
773	748	27820.37	Online	2025-10-05 14:48:35.805126+05:30	\N
774	749	74580.00	Card	2025-10-05 14:48:35.805126+05:30	\N
775	750	101565.14	Cash	2025-10-05 14:48:35.805126+05:30	\N
776	752	80850.00	Card	2025-10-05 14:48:35.805126+05:30	\N
777	753	100980.00	Card	2025-10-05 14:48:35.805126+05:30	\N
778	754	106920.00	Card	2025-10-05 14:48:35.805126+05:30	\N
779	755	72633.86	Cash	2025-10-05 14:48:35.805126+05:30	\N
780	756	132000.00	Card	2025-10-05 14:48:35.805126+05:30	\N
781	757	131010.00	Card	2025-10-05 14:48:35.805126+05:30	\N
782	758	30103.62	Cash	2025-10-05 14:48:35.805126+05:30	\N
783	759	167112.00	Card	2025-10-05 14:48:35.805126+05:30	\N
784	760	73040.00	Card	2025-10-05 14:48:35.805126+05:30	\N
785	761	119460.00	Card	2025-10-05 14:48:35.805126+05:30	\N
786	762	144540.00	Card	2025-10-05 14:48:35.805126+05:30	\N
787	764	99660.00	Card	2025-10-05 14:48:35.805126+05:30	\N
788	765	50311.23	Cash	2025-10-05 14:48:35.805126+05:30	\N
789	765	16099.38	Online	2025-10-05 14:48:35.805126+05:30	\N
790	766	44880.00	Card	2025-10-05 14:48:35.805126+05:30	\N
791	767	49060.00	Card	2025-10-05 14:48:35.805126+05:30	\N
792	769	99442.10	Cash	2025-10-05 14:48:35.805126+05:30	\N
793	769	29008.45	Online	2025-10-05 14:48:35.805126+05:30	\N
794	770	116820.00	Card	2025-10-05 14:48:35.805126+05:30	\N
795	771	59694.80	Card	2025-10-05 14:48:35.805126+05:30	\N
796	772	21780.00	Card	2025-10-05 14:48:35.805126+05:30	\N
797	773	59400.00	Card	2025-10-05 14:48:35.805126+05:30	\N
798	774	16054.06	Cash	2025-10-05 14:48:35.805126+05:30	\N
799	774	3291.24	Online	2025-10-05 14:48:35.805126+05:30	\N
800	775	59400.00	Card	2025-10-05 14:48:35.805126+05:30	\N
801	776	38287.63	Cash	2025-10-05 14:48:35.805126+05:30	\N
802	776	21186.69	Online	2025-10-05 14:48:35.805126+05:30	\N
803	777	19235.46	Cash	2025-10-05 14:48:35.805126+05:30	\N
804	777	7482.94	Online	2025-10-05 14:48:35.805126+05:30	\N
805	778	15236.22	Cash	2025-10-05 14:48:35.805126+05:30	\N
806	779	22550.00	Card	2025-10-05 14:48:35.805126+05:30	\N
807	780	139700.00	Card	2025-10-05 14:48:35.805126+05:30	\N
808	781	137676.00	Card	2025-10-05 14:48:35.805126+05:30	\N
809	782	32525.30	Cash	2025-10-05 14:48:35.805126+05:30	\N
810	783	119460.00	Card	2025-10-05 14:48:35.805126+05:30	\N
811	784	51664.80	Card	2025-10-05 14:48:35.805126+05:30	\N
812	787	23522.40	Card	2025-10-05 14:48:35.805126+05:30	\N
813	788	141680.00	Card	2025-10-05 14:48:35.805126+05:30	\N
814	789	63874.80	Card	2025-10-05 14:48:35.805126+05:30	\N
815	790	70891.94	Cash	2025-10-05 14:48:35.805126+05:30	\N
816	791	146410.00	Card	2025-10-05 14:48:35.805126+05:30	\N
817	792	141900.00	Card	2025-10-05 14:48:35.805126+05:30	\N
818	793	114840.00	Card	2025-10-05 14:48:35.805126+05:30	\N
819	795	33330.00	Card	2025-10-05 14:48:35.805126+05:30	\N
820	796	20537.06	Cash	2025-10-05 14:48:35.805126+05:30	\N
821	797	55843.62	Cash	2025-10-05 14:48:35.805126+05:30	\N
822	797	35467.19	Online	2025-10-05 14:48:35.805126+05:30	\N
823	798	157740.00	Card	2025-10-05 14:48:35.805126+05:30	\N
824	799	49684.80	Card	2025-10-05 14:48:35.805126+05:30	\N
825	800	65741.97	Cash	2025-10-05 14:48:35.805126+05:30	\N
826	801	84150.00	Card	2025-10-05 14:48:35.805126+05:30	\N
827	803	53336.91	Cash	2025-10-05 14:48:35.805126+05:30	\N
828	806	118470.00	Card	2025-10-05 14:48:35.805126+05:30	\N
829	807	37642.97	Cash	2025-10-05 14:48:35.805126+05:30	\N
830	807	22645.30	Online	2025-10-05 14:48:35.805126+05:30	\N
831	808	125400.00	Card	2025-10-05 14:48:35.805126+05:30	\N
832	809	105600.00	Card	2025-10-05 14:48:35.805126+05:30	\N
833	810	80520.00	Card	2025-10-05 14:48:35.805126+05:30	\N
834	811	79310.00	Card	2025-10-05 14:48:35.805126+05:30	\N
835	812	129967.20	Card	2025-10-05 14:48:35.805126+05:30	\N
836	813	146520.00	Card	2025-10-05 14:48:35.805126+05:30	\N
837	814	49930.46	Cash	2025-10-05 14:48:35.805126+05:30	\N
838	814	29269.54	Online	2025-10-05 14:48:35.805126+05:30	\N
839	816	83930.00	Card	2025-10-05 14:48:35.805126+05:30	\N
840	817	102300.00	Card	2025-10-05 14:48:35.805126+05:30	\N
841	818	95444.12	Cash	2025-10-05 14:48:35.805126+05:30	\N
842	818	32705.88	Online	2025-10-05 14:48:35.805126+05:30	\N
843	819	74527.20	Card	2025-10-05 14:48:35.805126+05:30	\N
844	820	89760.00	Card	2025-10-05 14:48:35.805126+05:30	\N
845	821	139370.00	Card	2025-10-05 14:48:35.805126+05:30	\N
846	822	141900.00	Card	2025-10-05 14:48:35.805126+05:30	\N
847	823	53680.00	Card	2025-10-05 14:48:35.805126+05:30	\N
848	824	33478.08	Cash	2025-10-05 14:48:35.805126+05:30	\N
849	825	46742.12	Cash	2025-10-05 14:48:35.805126+05:30	\N
850	826	77444.19	Cash	2025-10-05 14:48:35.805126+05:30	\N
851	827	63121.28	Cash	2025-10-05 14:48:35.805126+05:30	\N
852	827	36010.83	Online	2025-10-05 14:48:35.805126+05:30	\N
853	828	80669.36	Cash	2025-10-05 14:48:35.805126+05:30	\N
854	830	46796.46	Cash	2025-10-05 14:48:35.805126+05:30	\N
855	830	7184.74	Online	2025-10-05 14:48:35.805126+05:30	\N
856	831	60720.00	Card	2025-10-05 14:48:35.805126+05:30	\N
857	832	38622.04	Cash	2025-10-05 14:48:35.805126+05:30	\N
858	833	41580.00	Card	2025-10-05 14:48:35.805126+05:30	\N
859	834	11747.89	Cash	2025-10-05 14:48:35.805126+05:30	\N
860	837	50510.28	Cash	2025-10-05 14:48:35.805126+05:30	\N
861	838	71067.71	Cash	2025-10-05 14:48:35.805126+05:30	\N
862	838	25543.51	Online	2025-10-05 14:48:35.805126+05:30	\N
863	839	83490.00	Card	2025-10-05 14:48:35.805126+05:30	\N
864	840	37230.84	Cash	2025-10-05 14:48:35.805126+05:30	\N
865	841	53718.92	Cash	2025-10-05 14:48:35.805126+05:30	\N
866	842	70426.40	Card	2025-10-05 14:48:35.805126+05:30	\N
867	843	81895.42	Cash	2025-10-05 14:48:35.805126+05:30	\N
868	845	82478.00	Card	2025-10-05 14:48:35.805126+05:30	\N
869	846	140800.00	Card	2025-10-05 14:48:35.805126+05:30	\N
870	847	15728.42	Cash	2025-10-05 14:48:35.805126+05:30	\N
871	848	91423.20	Card	2025-10-05 14:48:35.805126+05:30	\N
872	849	77220.00	Card	2025-10-05 14:48:35.805126+05:30	\N
873	850	80044.80	Card	2025-10-05 14:48:35.805126+05:30	\N
874	851	71280.00	Card	2025-10-05 14:48:35.805126+05:30	\N
875	852	47030.34	Cash	2025-10-05 14:48:35.805126+05:30	\N
876	853	108768.00	Card	2025-10-05 14:48:35.805126+05:30	\N
877	854	72600.00	Card	2025-10-05 14:48:35.805126+05:30	\N
878	855	58168.00	Card	2025-10-05 14:48:35.805126+05:30	\N
879	856	79200.00	Card	2025-10-05 14:48:35.805126+05:30	\N
880	857	58630.00	Card	2025-10-05 14:48:35.805126+05:30	\N
881	860	14906.41	Cash	2025-10-05 14:48:35.805126+05:30	\N
882	861	160358.00	Card	2025-10-05 14:48:35.805126+05:30	\N
883	862	59510.00	Card	2025-10-05 14:48:35.805126+05:30	\N
884	863	90446.40	Card	2025-10-05 14:48:35.805126+05:30	\N
885	864	55140.53	Cash	2025-10-05 14:48:35.805126+05:30	\N
886	864	21539.64	Online	2025-10-05 14:48:35.805126+05:30	\N
887	865	32160.75	Cash	2025-10-05 14:48:35.805126+05:30	\N
888	866	71222.15	Cash	2025-10-05 14:48:35.805126+05:30	\N
889	867	14520.00	Card	2025-10-05 14:48:35.805126+05:30	\N
890	868	13522.59	Cash	2025-10-05 14:48:35.805126+05:30	\N
891	868	9843.22	Online	2025-10-05 14:48:35.805126+05:30	\N
892	869	163376.40	Card	2025-10-05 14:48:35.805126+05:30	\N
893	870	97460.00	Card	2025-10-05 14:48:35.805126+05:30	\N
894	871	24880.53	Cash	2025-10-05 14:48:35.805126+05:30	\N
895	873	49118.15	Cash	2025-10-05 14:48:35.805126+05:30	\N
896	874	73590.00	Card	2025-10-05 14:48:35.805126+05:30	\N
897	876	48958.00	Cash	2025-10-05 14:48:35.805126+05:30	\N
898	876	19873.23	Online	2025-10-05 14:48:35.805126+05:30	\N
899	877	106128.00	Card	2025-10-05 14:48:35.805126+05:30	\N
900	878	141240.00	Card	2025-10-05 14:48:35.805126+05:30	\N
901	879	86900.00	Card	2025-10-05 14:48:35.805126+05:30	\N
902	880	75652.27	Cash	2025-10-05 14:48:35.805126+05:30	\N
903	881	141900.00	Card	2025-10-05 14:48:35.805126+05:30	\N
904	882	75900.00	Card	2025-10-05 14:48:35.805126+05:30	\N
905	884	18456.65	Cash	2025-10-05 14:48:35.805126+05:30	\N
906	884	6541.50	Online	2025-10-05 14:48:35.805126+05:30	\N
907	885	50499.08	Cash	2025-10-05 14:48:35.805126+05:30	\N
908	886	60940.00	Card	2025-10-05 14:48:35.805126+05:30	\N
909	889	47397.63	Cash	2025-10-05 14:48:35.805126+05:30	\N
910	891	57812.95	Cash	2025-10-05 14:48:35.805126+05:30	\N
911	892	88110.00	Card	2025-10-05 14:48:35.805126+05:30	\N
912	895	65753.18	Cash	2025-10-05 14:48:35.805126+05:30	\N
913	896	16399.15	Cash	2025-10-05 14:48:35.805126+05:30	\N
914	897	59175.80	Cash	2025-10-05 14:48:35.805126+05:30	\N
915	898	26711.79	Cash	2025-10-05 14:48:35.805126+05:30	\N
916	898	25822.66	Online	2025-10-05 14:48:35.805126+05:30	\N
917	899	101750.00	Card	2025-10-05 14:48:35.805126+05:30	\N
918	900	59730.00	Card	2025-10-05 14:48:35.805126+05:30	\N
919	902	78540.00	Card	2025-10-05 14:48:35.805126+05:30	\N
920	903	98824.00	Card	2025-10-05 14:48:35.805126+05:30	\N
921	905	11157.68	Cash	2025-10-05 14:48:35.805126+05:30	\N
922	905	2954.73	Online	2025-10-05 14:48:35.805126+05:30	\N
923	906	37978.58	Cash	2025-10-05 14:48:35.805126+05:30	\N
924	907	62896.07	Cash	2025-10-05 14:48:35.805126+05:30	\N
925	907	39238.11	Online	2025-10-05 14:48:35.805126+05:30	\N
926	908	18981.60	Card	2025-10-05 14:48:35.805126+05:30	\N
927	912	30643.30	Cash	2025-10-05 14:48:35.805126+05:30	\N
928	913	69630.00	Card	2025-10-05 14:48:35.805126+05:30	\N
929	914	44863.97	Cash	2025-10-05 14:48:35.805126+05:30	\N
930	915	67210.00	Card	2025-10-05 14:48:35.805126+05:30	\N
931	917	51583.97	Cash	2025-10-05 14:48:35.805126+05:30	\N
932	918	82526.40	Card	2025-10-05 14:48:35.805126+05:30	\N
933	919	99660.00	Card	2025-10-05 14:48:35.805126+05:30	\N
934	920	141240.00	Card	2025-10-05 14:48:35.805126+05:30	\N
935	921	94894.80	Card	2025-10-05 14:48:35.805126+05:30	\N
936	922	53305.93	Cash	2025-10-05 14:48:35.805126+05:30	\N
937	923	42768.00	Card	2025-10-05 14:48:35.805126+05:30	\N
938	924	87780.00	Card	2025-10-05 14:48:35.805126+05:30	\N
939	925	19551.96	Cash	2025-10-05 14:48:35.805126+05:30	\N
940	925	4248.39	Online	2025-10-05 14:48:35.805126+05:30	\N
941	926	126865.78	Cash	2025-10-05 14:48:35.805126+05:30	\N
942	928	100980.00	Card	2025-10-05 14:48:35.805126+05:30	\N
943	929	45952.75	Cash	2025-10-05 14:48:35.805126+05:30	\N
944	929	16602.42	Online	2025-10-05 14:48:35.805126+05:30	\N
945	930	65197.03	Cash	2025-10-05 14:48:35.805126+05:30	\N
946	931	78408.00	Card	2025-10-05 14:48:35.805126+05:30	\N
947	932	11403.19	Cash	2025-10-05 14:48:35.805126+05:30	\N
948	933	135080.00	Card	2025-10-05 14:48:35.805126+05:30	\N
949	934	80300.00	Card	2025-10-05 14:48:35.805126+05:30	\N
950	935	17494.02	Cash	2025-10-05 14:48:35.805126+05:30	\N
951	935	14470.30	Online	2025-10-05 14:48:35.805126+05:30	\N
952	936	40899.26	Cash	2025-10-05 14:48:35.805126+05:30	\N
953	937	59070.00	Card	2025-10-05 14:48:35.805126+05:30	\N
954	938	103290.00	Card	2025-10-05 14:48:35.805126+05:30	\N
955	939	14527.56	Cash	2025-10-05 14:48:35.805126+05:30	\N
956	939	4616.86	Online	2025-10-05 14:48:35.805126+05:30	\N
957	940	45870.00	Card	2025-10-05 14:48:35.805126+05:30	\N
958	942	43597.44	Cash	2025-10-05 14:48:35.805126+05:30	\N
959	942	35785.76	Online	2025-10-05 14:48:35.805126+05:30	\N
960	943	77880.00	Card	2025-10-05 14:48:35.805126+05:30	\N
961	944	29170.13	Cash	2025-10-05 14:48:35.805126+05:30	\N
962	944	16512.42	Online	2025-10-05 14:48:35.805126+05:30	\N
963	945	105454.48	Cash	2025-10-05 14:48:35.805126+05:30	\N
964	945	40744.47	Online	2025-10-05 14:48:35.805126+05:30	\N
965	946	204600.00	Card	2025-10-05 14:48:35.805126+05:30	\N
966	947	276540.00	Card	2025-10-05 14:48:35.805126+05:30	\N
967	948	39705.61	Cash	2025-10-05 14:48:35.805126+05:30	\N
968	948	17410.53	Online	2025-10-05 14:48:35.805126+05:30	\N
969	949	135300.00	Card	2025-10-05 14:48:35.805126+05:30	\N
970	950	98751.24	Cash	2025-10-05 14:48:35.805126+05:30	\N
971	951	51040.39	Cash	2025-10-05 14:48:35.805126+05:30	\N
972	951	43335.93	Online	2025-10-05 14:48:35.805126+05:30	\N
973	953	121000.00	Card	2025-10-05 14:48:35.805126+05:30	\N
974	955	122185.97	Cash	2025-10-05 14:48:35.805126+05:30	\N
975	956	309100.00	Card	2025-10-05 14:48:35.805126+05:30	\N
976	957	152240.00	Card	2025-10-05 14:48:35.805126+05:30	\N
977	958	208340.00	Card	2025-10-05 14:48:35.805126+05:30	\N
978	959	77944.08	Cash	2025-10-05 14:48:35.805126+05:30	\N
979	960	59835.46	Cash	2025-10-05 14:48:35.805126+05:30	\N
980	962	102850.00	Card	2025-10-05 14:48:35.805126+05:30	\N
981	963	213048.00	Card	2025-10-05 14:48:35.805126+05:30	\N
982	964	70069.31	Cash	2025-10-05 14:48:35.805126+05:30	\N
983	965	143569.01	Cash	2025-10-05 14:48:35.805126+05:30	\N
984	966	153450.00	Card	2025-10-05 14:48:35.805126+05:30	\N
985	967	173140.00	Card	2025-10-05 14:48:35.805126+05:30	\N
986	968	34148.32	Cash	2025-10-05 14:48:35.805126+05:30	\N
987	969	206030.00	Card	2025-10-05 14:48:35.805126+05:30	\N
988	970	231440.00	Card	2025-10-05 14:48:35.805126+05:30	\N
989	971	178200.00	Card	2025-10-05 14:48:35.805126+05:30	\N
990	972	104500.00	Card	2025-10-05 14:48:35.805126+05:30	\N
991	974	217800.00	Card	2025-10-05 14:48:35.805126+05:30	\N
992	975	176330.00	Card	2025-10-05 14:48:35.805126+05:30	\N
993	976	304260.00	Card	2025-10-05 14:48:35.805126+05:30	\N
994	977	236808.00	Card	2025-10-05 14:48:35.805126+05:30	\N
995	978	58308.59	Cash	2025-10-05 14:48:35.805126+05:30	\N
996	979	229416.00	Card	2025-10-05 14:48:35.805126+05:30	\N
997	980	191400.00	Card	2025-10-05 14:48:35.805126+05:30	\N
998	981	277640.00	Card	2025-10-05 14:48:35.805126+05:30	\N
999	982	117260.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1000	984	91947.89	Cash	2025-10-05 14:48:35.805126+05:30	\N
1001	984	37788.56	Online	2025-10-05 14:48:35.805126+05:30	\N
1002	985	101554.60	Cash	2025-10-05 14:48:35.805126+05:30	\N
1003	986	136394.80	Cash	2025-10-05 14:48:35.805126+05:30	\N
1004	987	52272.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1005	988	106673.78	Cash	2025-10-05 14:48:35.805126+05:30	\N
1006	989	178640.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1007	990	88000.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1008	991	93824.01	Cash	2025-10-05 14:48:35.805126+05:30	\N
1009	991	37973.62	Online	2025-10-05 14:48:35.805126+05:30	\N
1010	992	162360.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1011	993	162360.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1012	994	288200.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1013	995	150700.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1014	996	110365.34	Cash	2025-10-05 14:48:35.805126+05:30	\N
1015	996	56232.16	Online	2025-10-05 14:48:35.805126+05:30	\N
1016	997	209088.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1017	998	117040.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1018	999	243980.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1019	1000	105050.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1020	1002	232518.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1021	1003	171453.14	Cash	2025-10-05 14:48:35.805126+05:30	\N
1022	1003	50547.27	Online	2025-10-05 14:48:35.805126+05:30	\N
1023	1004	121003.12	Cash	2025-10-05 14:48:35.805126+05:30	\N
1024	1007	284328.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1025	1008	75286.04	Cash	2025-10-05 14:48:35.805126+05:30	\N
1026	1009	212916.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1027	1010	103233.66	Cash	2025-10-05 14:48:35.805126+05:30	\N
1028	1011	145200.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1029	1012	9121.17	Cash	2025-10-05 14:48:35.805126+05:30	\N
1030	1014	103289.34	Cash	2025-10-05 14:48:35.805126+05:30	\N
1031	1014	42244.80	Online	2025-10-05 14:48:35.805126+05:30	\N
1032	1015	150810.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1033	1016	145200.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1034	1017	74800.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1035	1018	59683.43	Cash	2025-10-05 14:48:35.805126+05:30	\N
1036	1019	58080.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1037	1020	127160.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1038	1022	115526.40	Card	2025-10-05 14:48:35.805126+05:30	\N
1039	1024	242616.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1040	1025	133689.60	Card	2025-10-05 14:48:35.805126+05:30	\N
1041	1026	215160.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1042	1027	155042.80	Card	2025-10-05 14:48:35.805126+05:30	\N
1043	1029	112226.40	Card	2025-10-05 14:48:35.805126+05:30	\N
1044	1030	84132.49	Cash	2025-10-05 14:48:35.805126+05:30	\N
1045	1031	30149.94	Cash	2025-10-05 14:48:35.805126+05:30	\N
1046	1033	142502.80	Card	2025-10-05 14:48:35.805126+05:30	\N
1047	1037	93965.41	Cash	2025-10-05 14:48:35.805126+05:30	\N
1048	1037	53904.81	Online	2025-10-05 14:48:35.805126+05:30	\N
1049	1039	28512.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1050	1040	25989.19	Cash	2025-10-05 14:48:35.805126+05:30	\N
1051	1040	11633.36	Online	2025-10-05 14:48:35.805126+05:30	\N
1052	1041	56184.53	Cash	2025-10-05 14:48:35.805126+05:30	\N
1053	1041	18202.79	Online	2025-10-05 14:48:35.805126+05:30	\N
1054	1043	81212.24	Cash	2025-10-05 14:48:35.805126+05:30	\N
1055	1043	33737.76	Online	2025-10-05 14:48:35.805126+05:30	\N
1056	1044	31647.27	Cash	2025-10-05 14:48:35.805126+05:30	\N
1057	1045	231000.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1058	1046	75681.78	Cash	2025-10-05 14:48:35.805126+05:30	\N
1059	1046	43448.22	Online	2025-10-05 14:48:35.805126+05:30	\N
1060	1047	152900.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1061	1048	169510.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1062	1049	62726.40	Card	2025-10-05 14:48:35.805126+05:30	\N
1063	1050	97020.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1064	1051	16682.71	Cash	2025-10-05 14:48:35.805126+05:30	\N
1065	1052	125840.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1066	1053	129302.80	Card	2025-10-05 14:48:35.805126+05:30	\N
1067	1054	161700.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1068	1055	31887.03	Cash	2025-10-05 14:48:35.805126+05:30	\N
1069	1056	95415.66	Cash	2025-10-05 14:48:35.805126+05:30	\N
1070	1058	125563.65	Cash	2025-10-05 14:48:35.805126+05:30	\N
1071	1060	76474.68	Cash	2025-10-05 14:48:35.805126+05:30	\N
1072	1061	97262.24	Cash	2025-10-05 14:48:35.805126+05:30	\N
1073	1062	63481.67	Cash	2025-10-05 14:48:35.805126+05:30	\N
1074	1062	20788.38	Online	2025-10-05 14:48:35.805126+05:30	\N
1075	1063	117150.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1076	1064	108890.64	Cash	2025-10-05 14:48:35.805126+05:30	\N
1077	1065	36809.53	Cash	2025-10-05 14:48:35.805126+05:30	\N
1078	1065	16162.04	Online	2025-10-05 14:48:35.805126+05:30	\N
1079	1066	33485.76	Cash	2025-10-05 14:48:35.805126+05:30	\N
1080	1067	38860.95	Cash	2025-10-05 14:48:35.805126+05:30	\N
1081	1067	8327.00	Online	2025-10-05 14:48:35.805126+05:30	\N
1082	1069	106150.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1083	1070	157080.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1084	1071	68213.20	Card	2025-10-05 14:48:35.805126+05:30	\N
1085	1072	101336.40	Card	2025-10-05 14:48:35.805126+05:30	\N
1086	1073	194260.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1087	1074	129360.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1088	1075	89126.40	Card	2025-10-05 14:48:35.805126+05:30	\N
1089	1076	54561.33	Cash	2025-10-05 14:48:35.805126+05:30	\N
1090	1077	115521.69	Cash	2025-10-05 14:48:35.805126+05:30	\N
1091	1077	31351.58	Online	2025-10-05 14:48:35.805126+05:30	\N
1092	1078	66622.25	Cash	2025-10-05 14:48:35.805126+05:30	\N
1093	1079	63255.84	Cash	2025-10-05 14:48:35.805126+05:30	\N
1094	1079	15991.10	Online	2025-10-05 14:48:35.805126+05:30	\N
1095	1080	135248.24	Cash	2025-10-05 14:48:35.805126+05:30	\N
1096	1081	55501.94	Cash	2025-10-05 14:48:35.805126+05:30	\N
1097	1082	145200.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1098	1083	65838.03	Cash	2025-10-05 14:48:35.805126+05:30	\N
1099	1084	18953.27	Cash	2025-10-05 14:48:35.805126+05:30	\N
1100	1084	21118.76	Online	2025-10-05 14:48:35.805126+05:30	\N
1101	1085	103224.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1102	1089	102960.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1103	1091	118800.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1104	1092	125413.20	Card	2025-10-05 14:48:35.805126+05:30	\N
1105	1093	77880.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1106	1094	87120.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1107	1095	33463.32	Cash	2025-10-05 14:48:35.805126+05:30	\N
1108	1095	11717.25	Online	2025-10-05 14:48:35.805126+05:30	\N
1109	1096	47740.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1110	1097	55681.63	Cash	2025-10-05 14:48:35.805126+05:30	\N
1111	1097	20481.82	Online	2025-10-05 14:48:35.805126+05:30	\N
1112	1098	107580.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1113	1099	109230.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1114	1101	153450.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1115	1102	92072.22	Cash	2025-10-05 14:48:35.805126+05:30	\N
1116	1102	68944.24	Online	2025-10-05 14:48:35.805126+05:30	\N
1117	1104	39500.20	Cash	2025-10-05 14:48:35.805126+05:30	\N
1118	1105	88611.14	Cash	2025-10-05 14:48:35.805126+05:30	\N
1119	1106	94089.60	Card	2025-10-05 14:48:35.805126+05:30	\N
1120	1107	129360.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1121	1108	35896.46	Cash	2025-10-05 14:48:35.805126+05:30	\N
1122	1109	34650.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1123	1110	56485.23	Cash	2025-10-05 14:48:35.805126+05:30	\N
1124	1110	35434.01	Online	2025-10-05 14:48:35.805126+05:30	\N
1125	1111	178860.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1126	1112	110396.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1127	1113	53101.05	Cash	2025-10-05 14:48:35.805126+05:30	\N
1128	1113	46038.59	Online	2025-10-05 14:48:35.805126+05:30	\N
1129	1115	31900.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1130	1118	189970.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1131	1120	15200.99	Cash	2025-10-05 14:48:35.805126+05:30	\N
1132	1121	159940.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1133	1122	125452.80	Card	2025-10-05 14:48:35.805126+05:30	\N
1134	1123	74789.62	Cash	2025-10-05 14:48:35.805126+05:30	\N
1135	1123	25316.38	Online	2025-10-05 14:48:35.805126+05:30	\N
1136	1124	79200.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1137	1126	79724.73	Cash	2025-10-05 14:48:35.805126+05:30	\N
1138	1128	95040.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1139	1129	34980.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1140	1130	94089.60	Card	2025-10-05 14:48:35.805126+05:30	\N
1141	1131	53994.95	Cash	2025-10-05 14:48:35.805126+05:30	\N
1142	1131	34297.16	Online	2025-10-05 14:48:35.805126+05:30	\N
1143	1132	26222.82	Cash	2025-10-05 14:48:35.805126+05:30	\N
1144	1132	17593.22	Online	2025-10-05 14:48:35.805126+05:30	\N
1145	1133	76638.08	Cash	2025-10-05 14:48:35.805126+05:30	\N
1146	1133	31233.90	Online	2025-10-05 14:48:35.805126+05:30	\N
1147	1134	136620.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1148	1135	116160.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1149	1137	81392.50	Cash	2025-10-05 14:48:35.805126+05:30	\N
1150	1138	75278.15	Cash	2025-10-05 14:48:35.805126+05:30	\N
1151	1138	43409.38	Online	2025-10-05 14:48:35.805126+05:30	\N
1152	1142	31753.85	Cash	2025-10-05 14:48:35.805126+05:30	\N
1153	1142	11316.11	Online	2025-10-05 14:48:35.805126+05:30	\N
1154	1143	49363.67	Cash	2025-10-05 14:48:35.805126+05:30	\N
1155	1145	152240.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1156	1146	59316.76	Cash	2025-10-05 14:48:35.805126+05:30	\N
1157	1147	45430.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1158	1149	47826.93	Cash	2025-10-05 14:48:35.805126+05:30	\N
1159	1150	88624.80	Card	2025-10-05 14:48:35.805126+05:30	\N
1160	1151	49864.93	Cash	2025-10-05 14:48:35.805126+05:30	\N
1161	1152	124212.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1162	1153	88109.60	Cash	2025-10-05 14:48:35.805126+05:30	\N
1163	1154	88184.80	Card	2025-10-05 14:48:35.805126+05:30	\N
1164	1155	140800.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1165	1156	134640.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1166	1157	132000.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1167	1158	69482.48	Cash	2025-10-05 14:48:35.805126+05:30	\N
1168	1158	43382.00	Online	2025-10-05 14:48:35.805126+05:30	\N
1169	1159	41379.50	Cash	2025-10-05 14:48:35.805126+05:30	\N
1170	1159	24430.25	Online	2025-10-05 14:48:35.805126+05:30	\N
1171	1160	125400.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1172	1161	99550.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1173	1162	59400.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1174	1164	33192.96	Cash	2025-10-05 14:48:35.805126+05:30	\N
1175	1164	25182.26	Online	2025-10-05 14:48:35.805126+05:30	\N
1176	1165	36095.80	Cash	2025-10-05 14:48:35.805126+05:30	\N
1177	1165	6747.15	Online	2025-10-05 14:48:35.805126+05:30	\N
1178	1166	152829.60	Card	2025-10-05 14:48:35.805126+05:30	\N
1179	1167	83140.47	Cash	2025-10-05 14:48:35.805126+05:30	\N
1180	1167	26419.53	Online	2025-10-05 14:48:35.805126+05:30	\N
1181	1169	154566.91	Cash	2025-10-05 14:48:35.805126+05:30	\N
1182	1169	40172.69	Online	2025-10-05 14:48:35.805126+05:30	\N
1183	1171	140250.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1184	1172	85140.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1185	1173	49292.98	Cash	2025-10-05 14:48:35.805126+05:30	\N
1186	1173	10516.07	Online	2025-10-05 14:48:35.805126+05:30	\N
1187	1174	157779.60	Card	2025-10-05 14:48:35.805126+05:30	\N
1188	1175	72354.47	Cash	2025-10-05 14:48:35.805126+05:30	\N
1189	1176	42599.28	Cash	2025-10-05 14:48:35.805126+05:30	\N
1190	1176	13839.57	Online	2025-10-05 14:48:35.805126+05:30	\N
1191	1177	48712.40	Card	2025-10-05 14:48:35.805126+05:30	\N
1192	1178	128260.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1193	1179	65340.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1194	1180	143440.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1195	1181	81400.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1196	1182	75108.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1197	1184	34775.14	Cash	2025-10-05 14:48:35.805126+05:30	\N
1198	1184	10764.86	Online	2025-10-05 14:48:35.805126+05:30	\N
1199	1185	112640.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1200	1186	33723.83	Cash	2025-10-05 14:48:35.805126+05:30	\N
1201	1187	36425.01	Cash	2025-10-05 14:48:35.805126+05:30	\N
1202	1188	124740.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1203	1191	88440.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1204	1193	17911.31	Cash	2025-10-05 14:48:35.805126+05:30	\N
1205	1194	28193.56	Cash	2025-10-05 14:48:35.805126+05:30	\N
1206	1195	100113.95	Cash	2025-10-05 14:48:35.805126+05:30	\N
1207	1195	45015.65	Online	2025-10-05 14:48:35.805126+05:30	\N
1208	1196	40742.22	Cash	2025-10-05 14:48:35.805126+05:30	\N
1209	1197	87120.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1210	1198	73590.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1211	1199	89100.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1212	1200	94380.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1213	1201	35170.95	Cash	2025-10-05 14:48:35.805126+05:30	\N
1214	1201	5151.48	Online	2025-10-05 14:48:35.805126+05:30	\N
1215	1202	44552.41	Cash	2025-10-05 14:48:35.805126+05:30	\N
1216	1203	65842.93	Cash	2025-10-05 14:48:35.805126+05:30	\N
1217	1203	37688.39	Online	2025-10-05 14:48:35.805126+05:30	\N
1218	1204	112860.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1219	1205	47520.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1220	1206	217536.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1221	1207	68107.57	Cash	2025-10-05 14:48:35.805126+05:30	\N
1222	1208	172260.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1223	1211	138600.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1224	1212	18695.20	Cash	2025-10-05 14:48:35.805126+05:30	\N
1225	1213	157212.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1226	1214	60922.80	Cash	2025-10-05 14:48:35.805126+05:30	\N
1227	1214	18277.20	Online	2025-10-05 14:48:35.805126+05:30	\N
1228	1215	49892.60	Cash	2025-10-05 14:48:35.805126+05:30	\N
1229	1216	109890.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1230	1217	103180.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1231	1219	33037.33	Cash	2025-10-05 14:48:35.805126+05:30	\N
1232	1220	18206.33	Cash	2025-10-05 14:48:35.805126+05:30	\N
1233	1220	14916.16	Online	2025-10-05 14:48:35.805126+05:30	\N
1234	1221	60664.70	Cash	2025-10-05 14:48:35.805126+05:30	\N
1235	1221	13349.93	Online	2025-10-05 14:48:35.805126+05:30	\N
1236	1222	83939.70	Cash	2025-10-05 14:48:35.805126+05:30	\N
1237	1222	31305.10	Online	2025-10-05 14:48:35.805126+05:30	\N
1238	1223	146520.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1239	1224	87120.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1240	1225	155139.60	Card	2025-10-05 14:48:35.805126+05:30	\N
1241	1226	84480.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1242	1227	152829.60	Card	2025-10-05 14:48:35.805126+05:30	\N
1243	1228	73069.78	Cash	2025-10-05 14:48:35.805126+05:30	\N
1244	1229	162360.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1245	1230	79200.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1246	1231	64152.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1247	1232	79565.36	Cash	2025-10-05 14:48:35.805126+05:30	\N
1248	1233	123860.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1249	1234	84483.74	Cash	2025-10-05 14:48:35.805126+05:30	\N
1250	1234	24966.26	Online	2025-10-05 14:48:35.805126+05:30	\N
1251	1235	33575.19	Cash	2025-10-05 14:48:35.805126+05:30	\N
1252	1235	9192.81	Online	2025-10-05 14:48:35.805126+05:30	\N
1253	1237	89522.40	Card	2025-10-05 14:48:35.805126+05:30	\N
1254	1240	52847.76	Cash	2025-10-05 14:48:35.805126+05:30	\N
1255	1240	17044.43	Online	2025-10-05 14:48:35.805126+05:30	\N
1256	1241	19550.17	Cash	2025-10-05 14:48:35.805126+05:30	\N
1257	1241	7603.08	Online	2025-10-05 14:48:35.805126+05:30	\N
1258	1242	113520.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1259	1243	57100.62	Cash	2025-10-05 14:48:35.805126+05:30	\N
1260	1243	15544.63	Online	2025-10-05 14:48:35.805126+05:30	\N
1261	1244	51004.80	Card	2025-10-05 14:48:35.805126+05:30	\N
1262	1245	50160.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1263	1246	131472.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1264	1248	97612.19	Cash	2025-10-05 14:48:35.805126+05:30	\N
1265	1249	63934.84	Cash	2025-10-05 14:48:35.805126+05:30	\N
1266	1250	79200.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1267	1251	117546.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1268	1252	36440.89	Cash	2025-10-05 14:48:35.805126+05:30	\N
1269	1254	124410.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1270	1256	108900.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1271	1257	85536.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1272	1258	104830.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1273	1259	73865.38	Cash	2025-10-05 14:48:35.805126+05:30	\N
1274	1259	55288.72	Online	2025-10-05 14:48:35.805126+05:30	\N
1275	1260	179520.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1276	1261	32091.01	Cash	2025-10-05 14:48:35.805126+05:30	\N
1277	1262	43560.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1278	1263	45302.40	Card	2025-10-05 14:48:35.805126+05:30	\N
1279	1265	83402.89	Cash	2025-10-05 14:48:35.805126+05:30	\N
1280	1267	133100.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1281	1268	52889.07	Cash	2025-10-05 14:48:35.805126+05:30	\N
1282	1268	29855.29	Online	2025-10-05 14:48:35.805126+05:30	\N
1283	1269	66844.80	Card	2025-10-05 14:48:35.805126+05:30	\N
1284	1270	22867.48	Cash	2025-10-05 14:48:35.805126+05:30	\N
1285	1270	21630.57	Online	2025-10-05 14:48:35.805126+05:30	\N
1286	1271	51912.82	Cash	2025-10-05 14:48:35.805126+05:30	\N
1287	1271	14967.18	Online	2025-10-05 14:48:35.805126+05:30	\N
1288	1272	115429.60	Card	2025-10-05 14:48:35.805126+05:30	\N
1289	1273	87120.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1290	1274	45657.74	Cash	2025-10-05 14:48:35.805126+05:30	\N
1291	1274	20484.57	Online	2025-10-05 14:48:35.805126+05:30	\N
1292	1275	79860.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1293	1276	43919.24	Cash	2025-10-05 14:48:35.805126+05:30	\N
1294	1276	22511.27	Online	2025-10-05 14:48:35.805126+05:30	\N
1295	1277	90200.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1296	1278	28986.05	Cash	2025-10-05 14:48:35.805126+05:30	\N
1297	1278	16430.34	Online	2025-10-05 14:48:35.805126+05:30	\N
1298	1279	139920.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1299	1281	49984.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1300	1282	101824.42	Cash	2025-10-05 14:48:35.805126+05:30	\N
1301	1282	26873.66	Online	2025-10-05 14:48:35.805126+05:30	\N
1302	1283	70567.20	Card	2025-10-05 14:48:35.805126+05:30	\N
1303	1284	139920.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1304	1285	105639.60	Card	2025-10-05 14:48:35.805126+05:30	\N
1305	1286	148500.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1306	1287	82666.90	Cash	2025-10-05 14:48:35.805126+05:30	\N
1307	1287	15778.97	Online	2025-10-05 14:48:35.805126+05:30	\N
1308	1288	119592.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1309	1289	145310.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1310	1291	31703.41	Cash	2025-10-05 14:48:35.805126+05:30	\N
1311	1292	52984.80	Card	2025-10-05 14:48:35.805126+05:30	\N
1312	1293	117480.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1313	1295	72160.45	Cash	2025-10-05 14:48:35.805126+05:30	\N
1314	1296	43560.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1315	1297	74670.96	Cash	2025-10-05 14:48:35.805126+05:30	\N
1316	1297	33899.04	Online	2025-10-05 14:48:35.805126+05:30	\N
1317	1298	156860.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1318	1299	25022.82	Cash	2025-10-05 14:48:35.805126+05:30	\N
1319	1299	7891.82	Online	2025-10-05 14:48:35.805126+05:30	\N
1320	1300	82698.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1321	1302	85800.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1322	1303	58172.16	Cash	2025-10-05 14:48:35.805126+05:30	\N
1323	1303	36304.87	Online	2025-10-05 14:48:35.805126+05:30	\N
1324	1304	63756.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1325	1305	54397.19	Cash	2025-10-05 14:48:35.805126+05:30	\N
1326	1306	52800.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1327	1307	100980.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1328	1308	37405.05	Cash	2025-10-05 14:48:35.805126+05:30	\N
1329	1308	17523.50	Online	2025-10-05 14:48:35.805126+05:30	\N
1330	1309	43560.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1331	1310	154440.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1332	1312	81620.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1333	1313	193380.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1334	1314	113410.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1335	1315	57640.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1336	1316	93403.20	Card	2025-10-05 14:48:35.805126+05:30	\N
1337	1317	162250.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1338	1318	29651.66	Cash	2025-10-05 14:48:35.805126+05:30	\N
1339	1318	29608.84	Online	2025-10-05 14:48:35.805126+05:30	\N
1340	1319	70426.40	Card	2025-10-05 14:48:35.805126+05:30	\N
1341	1320	97680.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1342	1321	54780.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1343	1322	70400.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1344	1323	40698.74	Cash	2025-10-05 14:48:35.805126+05:30	\N
1345	1324	71500.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1346	1325	23332.46	Cash	2025-10-05 14:48:35.805126+05:30	\N
1347	1325	12091.43	Online	2025-10-05 14:48:35.805126+05:30	\N
1348	1327	17039.69	Cash	2025-10-05 14:48:35.805126+05:30	\N
1349	1328	97376.40	Card	2025-10-05 14:48:35.805126+05:30	\N
1350	1331	72186.40	Card	2025-10-05 14:48:35.805126+05:30	\N
1351	1332	49116.45	Cash	2025-10-05 14:48:35.805126+05:30	\N
1352	1332	42757.87	Online	2025-10-05 14:48:35.805126+05:30	\N
1353	1333	43560.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1354	1334	27218.15	Cash	2025-10-05 14:48:35.805126+05:30	\N
1355	1334	10187.83	Online	2025-10-05 14:48:35.805126+05:30	\N
1356	1336	71121.76	Cash	2025-10-05 14:48:35.805126+05:30	\N
1357	1336	26431.18	Online	2025-10-05 14:48:35.805126+05:30	\N
1358	1338	88110.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1359	1339	31790.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1360	1341	84713.20	Card	2025-10-05 14:48:35.805126+05:30	\N
1361	1342	52320.42	Cash	2025-10-05 14:48:35.805126+05:30	\N
1362	1343	64350.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1363	1344	40319.44	Cash	2025-10-05 14:48:35.805126+05:30	\N
1364	1345	94628.54	Cash	2025-10-05 14:48:35.805126+05:30	\N
1365	1345	26151.46	Online	2025-10-05 14:48:35.805126+05:30	\N
1366	1346	65340.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1367	1347	134640.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1368	1348	39600.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1369	1350	105600.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1370	1351	88563.20	Card	2025-10-05 14:48:35.805126+05:30	\N
1371	1353	112226.40	Card	2025-10-05 14:48:35.805126+05:30	\N
1372	1354	31348.92	Cash	2025-10-05 14:48:35.805126+05:30	\N
1373	1354	4699.02	Online	2025-10-05 14:48:35.805126+05:30	\N
1374	1355	72600.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1375	1356	79006.40	Card	2025-10-05 14:48:35.805126+05:30	\N
1376	1358	109780.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1377	1359	23024.22	Cash	2025-10-05 14:48:35.805126+05:30	\N
1378	1359	13643.82	Online	2025-10-05 14:48:35.805126+05:30	\N
1379	1360	132440.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1380	1362	31010.77	Cash	2025-10-05 14:48:35.805126+05:30	\N
1381	1363	53205.15	Cash	2025-10-05 14:48:35.805126+05:30	\N
1382	1363	55409.58	Online	2025-10-05 14:48:35.805126+05:30	\N
1383	1365	19871.01	Cash	2025-10-05 14:48:35.805126+05:30	\N
1384	1366	48923.45	Cash	2025-10-05 14:48:35.805126+05:30	\N
1385	1367	72182.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1386	1368	107580.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1387	1369	52800.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1388	1370	28977.21	Cash	2025-10-05 14:48:35.805126+05:30	\N
1389	1371	41302.52	Cash	2025-10-05 14:48:35.805126+05:30	\N
1390	1371	15392.27	Online	2025-10-05 14:48:35.805126+05:30	\N
1391	1372	56931.60	Card	2025-10-05 14:48:35.805126+05:30	\N
1392	1374	29040.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1393	1375	64020.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1394	1376	48963.20	Card	2025-10-05 14:48:35.805126+05:30	\N
1395	1377	140910.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1396	1379	114840.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1397	1380	46404.63	Cash	2025-10-05 14:48:35.805126+05:30	\N
1398	1380	13627.81	Online	2025-10-05 14:48:35.805126+05:30	\N
1399	1381	112226.40	Card	2025-10-05 14:48:35.805126+05:30	\N
1400	1382	24724.36	Cash	2025-10-05 14:48:35.805126+05:30	\N
1401	1384	62641.60	Cash	2025-10-05 14:48:35.805126+05:30	\N
1402	1385	70364.80	Card	2025-10-05 14:48:35.805126+05:30	\N
1403	1386	22385.15	Cash	2025-10-05 14:48:35.805126+05:30	\N
1404	1386	22141.42	Online	2025-10-05 14:48:35.805126+05:30	\N
1405	1387	26159.46	Cash	2025-10-05 14:48:35.805126+05:30	\N
1406	1388	57024.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1407	1389	65450.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1408	1390	39600.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1409	1391	31922.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1410	1393	51338.46	Cash	2025-10-05 14:48:35.805126+05:30	\N
1411	1394	15681.60	Card	2025-10-05 14:48:35.805126+05:30	\N
1412	1395	68666.40	Card	2025-10-05 14:48:35.805126+05:30	\N
1413	1396	57530.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1414	1397	25548.67	Cash	2025-10-05 14:48:35.805126+05:30	\N
1415	1397	9282.30	Online	2025-10-05 14:48:35.805126+05:30	\N
1416	1399	40282.96	Cash	2025-10-05 14:48:35.805126+05:30	\N
1417	1399	9963.97	Online	2025-10-05 14:48:35.805126+05:30	\N
1418	1401	32380.19	Cash	2025-10-05 14:48:35.805126+05:30	\N
1419	1402	69960.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1420	1403	9840.75	Cash	2025-10-05 14:48:35.805126+05:30	\N
1421	1404	39062.95	Cash	2025-10-05 14:48:35.805126+05:30	\N
1422	1404	17185.72	Online	2025-10-05 14:48:35.805126+05:30	\N
1423	1405	35079.48	Cash	2025-10-05 14:48:35.805126+05:30	\N
1424	1405	9312.12	Online	2025-10-05 14:48:35.805126+05:30	\N
1425	1406	78100.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1426	1407	49170.00	Card	2025-10-05 14:48:35.805126+05:30	\N
1427	1408	93777.47	Cash	2025-10-05 14:48:35.805126+05:30	\N
1428	1409	53534.80	Card	2025-10-05 14:48:35.805126+05:30	\N
1429	1410	16938.39	Cash	2025-10-05 14:48:35.805126+05:30	\N
1430	1410	10398.32	Online	2025-10-05 14:48:35.805126+05:30	\N
1432	4	38824.97	Online	2025-10-05 15:02:17.08014+05:30	\N
1433	30	8969.27	Cash	2025-10-05 15:02:17.08014+05:30	\N
1434	37	40593.42	Card	2025-10-05 15:02:17.08014+05:30	\N
1435	38	16220.19	Card	2025-10-05 15:02:17.08014+05:30	\N
1436	49	2821.71	BankTransfer	2025-10-05 15:02:17.08014+05:30	\N
1437	51	40241.65	Online	2025-10-05 15:02:17.08014+05:30	\N
1438	8	41713.78	BankTransfer	2025-10-05 15:02:17.08014+05:30	\N
1439	111	9437.71	Online	2025-10-05 15:02:17.08014+05:30	\N
1440	120	6081.85	Cash	2025-10-05 15:02:17.08014+05:30	\N
1441	139	11181.30	BankTransfer	2025-10-05 15:02:17.08014+05:30	\N
1442	144	3752.23	Online	2025-10-05 15:02:17.08014+05:30	\N
1443	130	23636.57	Online	2025-10-05 15:02:17.08014+05:30	\N
1444	221	12821.44	Cash	2025-10-05 15:02:17.08014+05:30	\N
1445	207	13707.27	Online	2025-10-05 15:02:17.08014+05:30	\N
1446	171	11856.57	Cash	2025-10-05 15:02:17.08014+05:30	\N
1447	201	7379.70	Cash	2025-10-05 15:02:17.08014+05:30	\N
1448	223	21152.32	BankTransfer	2025-10-05 15:02:17.08014+05:30	\N
1449	181	12117.14	Cash	2025-10-05 15:02:17.08014+05:30	\N
1450	191	10441.49	Cash	2025-10-05 15:02:17.08014+05:30	\N
1451	211	42770.87	Cash	2025-10-05 15:02:17.08014+05:30	\N
1452	245	29169.52	BankTransfer	2025-10-05 15:02:17.08014+05:30	\N
1453	218	2497.56	Card	2025-10-05 15:02:17.08014+05:30	\N
1454	219	2798.16	Card	2025-10-05 15:02:17.08014+05:30	\N
1455	252	31999.03	Cash	2025-10-05 15:02:17.08014+05:30	\N
1456	276	4293.09	Online	2025-10-05 15:02:17.08014+05:30	\N
1457	297	10202.97	BankTransfer	2025-10-05 15:02:17.08014+05:30	\N
1458	324	20633.43	Online	2025-10-05 15:02:17.08014+05:30	\N
1459	283	22738.87	BankTransfer	2025-10-05 15:02:17.08014+05:30	\N
1460	319	7652.89	Online	2025-10-05 15:02:17.08014+05:30	\N
1461	248	10561.09	Online	2025-10-05 15:02:17.08014+05:30	\N
1462	267	5042.03	Online	2025-10-05 15:02:17.08014+05:30	\N
1463	269	6784.64	Card	2025-10-05 15:02:17.08014+05:30	\N
1464	287	14014.83	BankTransfer	2025-10-05 15:02:17.08014+05:30	\N
1465	289	555.21	Online	2025-10-05 15:02:17.08014+05:30	\N
1466	292	3227.42	Cash	2025-10-05 15:02:17.08014+05:30	\N
1467	307	1582.37	BankTransfer	2025-10-05 15:02:17.08014+05:30	\N
1468	310	1148.14	Cash	2025-10-05 15:02:17.08014+05:30	\N
1469	266	455.17	Cash	2025-10-05 15:02:17.08014+05:30	\N
1470	335	5988.95	Online	2025-10-05 15:02:17.08014+05:30	\N
1471	350	7572.89	Card	2025-10-05 15:02:17.08014+05:30	\N
1472	360	32558.66	Cash	2025-10-05 15:02:17.08014+05:30	\N
1473	367	6853.44	BankTransfer	2025-10-05 15:02:17.08014+05:30	\N
1474	374	6377.04	Cash	2025-10-05 15:02:17.08014+05:30	\N
1475	390	16580.12	Online	2025-10-05 15:02:17.08014+05:30	\N
1476	398	6956.51	Online	2025-10-05 15:02:17.08014+05:30	\N
1477	382	13320.50	Online	2025-10-05 15:02:17.08014+05:30	\N
1478	370	564.41	Cash	2025-10-05 15:02:17.08014+05:30	\N
1479	346	3226.23	Cash	2025-10-05 15:02:17.08014+05:30	\N
1480	395	299.56	Online	2025-10-05 15:02:17.08014+05:30	\N
1481	409	3263.43	Cash	2025-10-05 15:02:17.08014+05:30	\N
1482	458	22730.50	Online	2025-10-05 15:02:17.08014+05:30	\N
1483	487	14077.99	BankTransfer	2025-10-05 15:02:17.08014+05:30	\N
1484	440	11649.65	Online	2025-10-05 15:02:17.08014+05:30	\N
1485	499	21908.68	BankTransfer	2025-10-05 15:02:17.08014+05:30	\N
1486	504	19238.27	BankTransfer	2025-10-05 15:02:17.08014+05:30	\N
1487	535	34800.15	Card	2025-10-05 15:02:17.08014+05:30	\N
1488	538	4548.88	Cash	2025-10-05 15:02:17.08014+05:30	\N
1489	544	8401.29	Online	2025-10-05 15:02:17.08014+05:30	\N
1490	552	28292.21	BankTransfer	2025-10-05 15:02:17.08014+05:30	\N
1491	567	51054.94	Cash	2025-10-05 15:02:17.08014+05:30	\N
1492	570	1751.81	Online	2025-10-05 15:02:17.08014+05:30	\N
1493	507	6413.26	Card	2025-10-05 15:02:17.08014+05:30	\N
1494	519	5437.21	Online	2025-10-05 15:02:17.08014+05:30	\N
1495	532	34011.92	BankTransfer	2025-10-05 15:02:17.08014+05:30	\N
1496	539	66733.81	Cash	2025-10-05 15:02:17.08014+05:30	\N
1497	491	8083.62	Cash	2025-10-05 15:02:17.08014+05:30	\N
1498	547	1382.50	Online	2025-10-05 15:02:17.08014+05:30	\N
1499	497	107.49	Online	2025-10-05 15:02:17.08014+05:30	\N
1500	590	35941.19	Cash	2025-10-05 15:02:17.08014+05:30	\N
1501	631	11072.38	Cash	2025-10-05 15:02:17.08014+05:30	\N
1502	636	40750.43	Cash	2025-10-05 15:02:17.08014+05:30	\N
1503	639	42108.26	Online	2025-10-05 15:02:17.08014+05:30	\N
1504	640	1745.12	Online	2025-10-05 15:02:17.08014+05:30	\N
1505	649	52027.14	Cash	2025-10-05 15:02:17.08014+05:30	\N
1506	651	6117.36	Online	2025-10-05 15:02:17.08014+05:30	\N
1507	578	24515.34	Cash	2025-10-05 15:02:17.08014+05:30	\N
1508	642	21177.31	Cash	2025-10-05 15:02:17.08014+05:30	\N
1509	671	12258.80	Cash	2025-10-05 15:02:17.08014+05:30	\N
1510	698	6481.91	Cash	2025-10-05 15:02:17.08014+05:30	\N
1511	700	54167.96	Cash	2025-10-05 15:02:17.08014+05:30	\N
1512	702	2147.73	BankTransfer	2025-10-05 15:02:17.08014+05:30	\N
1513	703	10117.90	Cash	2025-10-05 15:02:17.08014+05:30	\N
1514	662	764.49	Cash	2025-10-05 15:02:17.08014+05:30	\N
1515	691	3383.75	Cash	2025-10-05 15:02:17.08014+05:30	\N
1516	743	1.13	BankTransfer	2025-10-05 15:02:17.08014+05:30	\N
1517	790	20001.98	Card	2025-10-05 15:02:17.08014+05:30	\N
1518	800	9019.32	Online	2025-10-05 15:02:17.08014+05:30	\N
1519	777	4047.47	Online	2025-10-05 15:02:17.08014+05:30	\N
1520	741	26179.72	BankTransfer	2025-10-05 15:02:17.08014+05:30	\N
1521	796	20882.04	Cash	2025-10-05 15:02:17.08014+05:30	\N
1522	824	12758.55	Cash	2025-10-05 15:02:17.08014+05:30	\N
1523	826	19939.91	BankTransfer	2025-10-05 15:02:17.08014+05:30	\N
1524	827	3208.86	Online	2025-10-05 15:02:17.08014+05:30	\N
1525	838	91.11	Online	2025-10-05 15:02:17.08014+05:30	\N
1526	847	6749.70	Online	2025-10-05 15:02:17.08014+05:30	\N
1527	860	8331.78	Online	2025-10-05 15:02:17.08014+05:30	\N
1528	876	20621.14	Cash	2025-10-05 15:02:17.08014+05:30	\N
1529	895	14437.10	Cash	2025-10-05 15:02:17.08014+05:30	\N
1530	828	18743.69	Cash	2025-10-05 15:02:17.08014+05:30	\N
1531	866	15634.31	Cash	2025-10-05 15:02:17.08014+05:30	\N
1532	884	3721.37	Online	2025-10-05 15:02:17.08014+05:30	\N
1533	817	2006.00	BankTransfer	2025-10-05 15:02:17.08014+05:30	\N
1534	857	1976.15	Card	2025-10-05 15:02:17.08014+05:30	\N
1535	864	3937.93	Online	2025-10-05 15:02:17.08014+05:30	\N
1536	898	14009.71	Cash	2025-10-05 15:02:17.08014+05:30	\N
1537	926	19370.58	BankTransfer	2025-10-05 15:02:17.08014+05:30	\N
1538	930	8591.70	Card	2025-10-05 15:02:17.08014+05:30	\N
1539	935	15629.94	Cash	2025-10-05 15:02:17.08014+05:30	\N
1540	936	15498.88	Online	2025-10-05 15:02:17.08014+05:30	\N
1541	942	4616.28	Card	2025-10-05 15:02:17.08014+05:30	\N
1542	950	9176.07	Cash	2025-10-05 15:02:17.08014+05:30	\N
1543	951	26006.08	Card	2025-10-05 15:02:17.08014+05:30	\N
1544	965	47367.86	Card	2025-10-05 15:02:17.08014+05:30	\N
1545	925	2868.49	Online	2025-10-05 15:02:17.08014+05:30	\N
1546	917	54513.53	Card	2025-10-05 15:02:17.08014+05:30	\N
1547	948	9691.36	Online	2025-10-05 15:02:17.08014+05:30	\N
1548	964	12373.18	Cash	2025-10-05 15:02:17.08014+05:30	\N
1549	968	49471.92	Card	2025-10-05 15:02:17.08014+05:30	\N
1550	1003	2708.73	BankTransfer	2025-10-05 15:02:17.08014+05:30	\N
1551	1004	24181.38	Online	2025-10-05 15:02:17.08014+05:30	\N
1552	1008	7096.94	Card	2025-10-05 15:02:17.08014+05:30	\N
1553	1010	60675.91	Cash	2025-10-05 15:02:17.08014+05:30	\N
1554	1012	4117.22	Cash	2025-10-05 15:02:17.08014+05:30	\N
1555	1018	18938.81	Cash	2025-10-05 15:02:17.08014+05:30	\N
1556	1051	9862.84	BankTransfer	2025-10-05 15:02:17.08014+05:30	\N
1557	1055	43476.38	BankTransfer	2025-10-05 15:02:17.08014+05:30	\N
1558	978	16517.72	Online	2025-10-05 15:02:17.08014+05:30	\N
1559	988	55330.14	BankTransfer	2025-10-05 15:02:17.08014+05:30	\N
1560	986	29026.05	Cash	2025-10-05 15:02:17.08014+05:30	\N
1561	999	2054.53	BankTransfer	2025-10-05 15:02:17.08014+05:30	\N
1562	1062	3568.51	Card	2025-10-05 15:02:17.08014+05:30	\N
1563	1065	394.70	Online	2025-10-05 15:02:17.08014+05:30	\N
1564	1076	5480.53	Cash	2025-10-05 15:02:17.08014+05:30	\N
1565	1081	47810.57	Cash	2025-10-05 15:02:17.08014+05:30	\N
1566	1083	42722.65	Cash	2025-10-05 15:02:17.08014+05:30	\N
1567	1095	14109.52	Cash	2025-10-05 15:02:17.08014+05:30	\N
1568	1104	24944.34	Cash	2025-10-05 15:02:17.08014+05:30	\N
1569	1105	16058.56	Cash	2025-10-05 15:02:17.08014+05:30	\N
1570	1110	17133.96	Online	2025-10-05 15:02:17.08014+05:30	\N
1571	1113	18070.01	Card	2025-10-05 15:02:17.08014+05:30	\N
1572	1126	50553.98	Online	2025-10-05 15:02:17.08014+05:30	\N
1573	1131	7475.47	Cash	2025-10-05 15:02:17.08014+05:30	\N
1574	1077	9251.01	Online	2025-10-05 15:02:17.08014+05:30	\N
1575	1097	28634.02	Card	2025-10-05 15:02:17.08014+05:30	\N
1576	1138	5073.06	Online	2025-10-05 15:02:17.08014+05:30	\N
1577	1146	29076.93	BankTransfer	2025-10-05 15:02:17.08014+05:30	\N
1578	1153	14032.22	Cash	2025-10-05 15:02:17.08014+05:30	\N
1579	1165	2158.11	BankTransfer	2025-10-05 15:02:17.08014+05:30	\N
1580	1173	2376.20	Cash	2025-10-05 15:02:17.08014+05:30	\N
1581	1176	36208.98	Cash	2025-10-05 15:02:17.08014+05:30	\N
1582	1186	29208.69	Cash	2025-10-05 15:02:17.08014+05:30	\N
1583	1187	11713.15	BankTransfer	2025-10-05 15:02:17.08014+05:30	\N
1584	1193	16980.17	Cash	2025-10-05 15:02:17.08014+05:30	\N
1585	1196	19595.86	Online	2025-10-05 15:02:17.08014+05:30	\N
1586	1201	5956.90	Card	2025-10-05 15:02:17.08014+05:30	\N
1587	1219	7041.65	BankTransfer	2025-10-05 15:02:17.08014+05:30	\N
1588	1220	3444.72	Card	2025-10-05 15:02:17.08014+05:30	\N
1589	1149	11900.23	Card	2025-10-05 15:02:17.08014+05:30	\N
1590	1215	4153.32	Online	2025-10-05 15:02:17.08014+05:30	\N
1591	1221	3253.08	BankTransfer	2025-10-05 15:02:17.08014+05:30	\N
1592	1143	18213.29	BankTransfer	2025-10-05 15:02:17.08014+05:30	\N
1593	1228	8895.61	Online	2025-10-05 15:02:17.08014+05:30	\N
1594	1240	7104.65	Online	2025-10-05 15:02:17.08014+05:30	\N
1595	1278	21843.05	Online	2025-10-05 15:02:17.08014+05:30	\N
1596	1291	14600.14	Cash	2025-10-05 15:02:17.08014+05:30	\N
1597	1261	2949.31	Cash	2025-10-05 15:02:17.08014+05:30	\N
1598	1276	13313.72	Cash	2025-10-05 15:02:17.08014+05:30	\N
1599	1302	1113.64	Card	2025-10-05 15:02:17.08014+05:30	\N
1600	1241	11431.18	Card	2025-10-05 15:02:17.08014+05:30	\N
1601	1318	5698.35	Cash	2025-10-05 15:02:17.08014+05:30	\N
1602	1323	22585.99	BankTransfer	2025-10-05 15:02:17.08014+05:30	\N
1603	1325	6066.09	Online	2025-10-05 15:02:17.08014+05:30	\N
1604	1332	19938.10	Cash	2025-10-05 15:02:17.08014+05:30	\N
1605	1342	26380.22	Online	2025-10-05 15:02:17.08014+05:30	\N
1606	1370	13480.27	Card	2025-10-05 15:02:17.08014+05:30	\N
1607	1371	9251.95	Online	2025-10-05 15:02:17.08014+05:30	\N
1608	1380	4456.71	Cash	2025-10-05 15:02:17.08014+05:30	\N
1609	1303	10624.99	BankTransfer	2025-10-05 15:02:17.08014+05:30	\N
1610	1327	5115.91	Online	2025-10-05 15:02:17.08014+05:30	\N
1611	1359	11361.07	Online	2025-10-05 15:02:17.08014+05:30	\N
1612	1384	10968.46	BankTransfer	2025-10-05 15:02:17.08014+05:30	\N
1613	1399	8687.72	Card	2025-10-05 15:02:17.08014+05:30	\N
1614	1401	8871.65	Cash	2025-10-05 15:02:17.08014+05:30	\N
1615	129	39434.44	Online	2025-10-05 15:02:17.08014+05:30	\N
1616	232	3223.66	Cash	2025-10-05 15:02:17.08014+05:30	\N
1617	327	24320.33	Cash	2025-10-05 15:02:17.08014+05:30	\N
1618	435	35522.09	Cash	2025-10-05 15:02:17.08014+05:30	\N
1619	462	15417.79	Online	2025-10-05 15:02:17.08014+05:30	\N
1620	1386	4616.40	Cash	2025-10-05 15:02:17.08014+05:30	\N
1621	1387	20752.03	Card	2025-10-05 15:02:17.08014+05:30	\N
1622	156	6481.86	Cash	2025-10-05 15:02:17.08014+05:30	\N
1623	619	8277.96	Online	2025-10-05 15:02:17.08014+05:30	\N
1624	896	8246.04	Online	2025-10-05 15:02:17.08014+05:30	\N
1625	929	13002.94	Cash	2025-10-05 15:02:17.08014+05:30	\N
1626	932	1405.26	BankTransfer	2025-10-05 15:02:17.08014+05:30	\N
1627	605	6098.81	Card	2025-10-05 15:02:17.08014+05:30	\N
1628	593	18115.67	BankTransfer	2025-10-05 15:02:17.08014+05:30	\N
1629	1282	9555.77	Online	2025-10-05 15:02:17.08014+05:30	\N
1630	1287	10741.39	Card	2025-10-05 15:02:17.08014+05:30	\N
1631	1308	8803.91	BankTransfer	2025-10-05 15:02:17.08014+05:30	\N
1632	1403	6665.84	Cash	2025-10-05 15:02:17.08014+05:30	\N
1633	304	10020.68	Online	2025-10-05 15:02:17.08014+05:30	\N
1634	1132	298.29	Cash	2025-10-05 15:02:17.08014+05:30	\N
1635	436	3887.52	Cash	2025-10-05 15:02:17.08014+05:30	\N
1636	606	10577.60	Online	2025-10-05 15:02:17.08014+05:30	\N
1637	1120	5826.02	Online	2025-10-05 15:02:17.08014+05:30	\N
1638	1320	101.93	Card	2025-10-05 15:02:17.08014+05:30	\N
1639	1016	703.74	Online	2025-10-05 15:02:17.08014+05:30	\N
1640	1299	1605.73	Online	2025-10-05 15:02:17.08014+05:30	\N
1641	237	6837.61	Cash	2025-10-05 15:02:17.08014+05:30	\N
1642	233	1041.30	BankTransfer	2025-10-05 15:02:17.08014+05:30	\N
1643	868	3867.53	BankTransfer	2025-10-05 15:02:17.08014+05:30	\N
1644	123	5000.00	Card	2025-10-05 16:55:15.391748+05:30	\N
1645	501	20000.00	Online	2025-10-05 17:39:10.469573+05:30	ADV-501-001
1646	1441	8000.00	Card	2025-10-07 12:52:29.221709+05:30	\N
1647	1441	5000.00	Card	2025-10-07 12:59:03.067623+05:30	ADV2025-01
1650	1441	6000.00	Cash	2025-10-07 13:05:13.711961+05:30	CHECKIN-2025-02
1651	1441	8000.00	Card	2025-10-07 13:05:21.546271+05:30	\N
1654	1441	8000.00	Card	2025-10-07 13:05:51.318828+05:30	\N
1656	1441	6000.00	Cash	2025-10-07 13:08:15.954529+05:30	CHECKIN-2025-03
1662	1441	6000.00	Cash	2025-10-07 13:15:18.5651+05:30	CHECKIN
1664	1441	6000.00	Cash	2025-10-07 13:15:46.288797+05:30	CHECKIN-
1665	1441	20000.00	Card	2025-11-11 10:30:00+05:30	POS-98765
1668	1449	5000.00	Cash	2025-11-11 00:00:00+05:30	\N
1669	1453	5000.00	Card	2025-10-07 20:12:53.650944+05:30	ADV-12345
1670	1457	4000.00	Card	2025-10-07 20:13:50.131468+05:30	ADV-12345
1671	1458	4000.00	Card	2025-10-07 20:19:55.782881+05:30	ADV-12345
\.


--
-- TOC entry 5545 (class 0 OID 17264)
-- Dependencies: 235
-- Data for Name: payment_adjustment; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.payment_adjustment (adjustment_id, booking_id, amount, type, reference_note, created_at) FROM stdin;
1	501	20000.00	refund	Advance refund after early cancellation	2025-10-05 17:37:08.217675+05:30
2	501	20000.00	refund	Auto refund of advance on cancel	2025-10-05 17:40:05.827774+05:30
3	501	20000.00	refund	Advance refunded to guest	2025-10-05 17:40:47.592692+05:30
7	1441	300.00	manual_adjustment	\N	2025-10-07 18:24:10.645397+05:30
8	1441	500.00	refund	\N	2025-10-07 18:25:03.688498+05:30
9	1441	500.00	refund	\N	2025-10-07 18:31:44.18588+05:30
10	1441	500.00	refund	\N	2025-10-07 18:36:43.810438+05:30
11	1441	500.00	refund	\N	2025-10-07 18:47:24.64951+05:30
12	1441	500.00	refund	\N	2025-10-07 18:47:32.288052+05:30
13	1441	500.00	refund	\N	2025-10-07 18:48:04.094902+05:30
14	1441	500.00	refund	\N	2025-10-07 18:48:05.778295+05:30
\.


--
-- TOC entry 5548 (class 0 OID 17276)
-- Dependencies: 238
-- Data for Name: pre_booking; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pre_booking (pre_booking_id, guest_id, capacity, prebooking_method, expected_check_in, expected_check_out, room_id, created_by_employee_id, created_at) FROM stdin;
1	1	2	Online	2025-10-20	2025-10-23	\N	\N	2025-10-06 23:26:52.053112+05:30
2	2	2	Online	2025-10-20	2025-10-23	\N	\N	2025-10-06 23:26:52.053112+05:30
3	3	2	Online	2025-10-20	2025-10-23	\N	\N	2025-10-06 23:26:52.053112+05:30
4	1	2	Phone	2025-10-25	2025-10-28	20	\N	2025-10-06 23:26:52.053112+05:30
5	1	2	Phone	2025-10-25	2025-10-28	40	\N	2025-10-06 23:26:52.053112+05:30
6	1	2	Phone	2025-10-25	2025-10-28	60	\N	2025-10-06 23:26:52.053112+05:30
\.


--
-- TOC entry 5550 (class 0 OID 17288)
-- Dependencies: 240
-- Data for Name: room; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.room (room_id, branch_id, room_type_id, room_number, status) FROM stdin;
1	1	4	120	Available
2	1	4	119	Available
3	1	4	118	Available
4	1	3	117	Available
5	1	3	116	Available
6	1	3	115	Available
7	1	3	114	Available
8	1	3	113	Available
9	1	2	112	Available
10	1	2	111	Available
13	1	2	108	Available
15	1	2	106	Available
17	1	1	104	Available
18	1	1	103	Available
19	1	1	102	Available
20	1	1	101	Available
21	2	4	220	Available
22	2	4	219	Available
23	2	4	218	Available
24	2	3	217	Available
25	2	3	216	Available
26	2	3	215	Available
27	2	3	214	Available
28	2	3	213	Available
29	2	2	212	Available
30	2	2	211	Available
32	2	2	209	Available
33	2	2	208	Available
34	2	2	207	Available
35	2	2	206	Available
36	2	1	205	Available
37	2	1	204	Available
38	2	1	203	Available
39	2	1	202	Available
40	2	1	201	Available
41	3	4	320	Available
42	3	4	319	Available
43	3	4	318	Available
44	3	3	317	Available
45	3	3	316	Available
46	3	3	315	Available
47	3	3	314	Available
48	3	3	313	Available
49	3	2	312	Available
50	3	2	311	Available
52	3	2	309	Available
53	3	2	308	Available
54	3	2	307	Available
55	3	2	306	Available
56	3	1	305	Available
57	3	1	304	Available
58	3	1	303	Available
59	3	1	302	Available
60	3	1	301	Available
11	1	2	110	Maintenance
31	2	2	210	Maintenance
51	3	2	310	Maintenance
12	1	4	109	Available
14	1	3	107	Available
16	1	2	105	Available
\.


--
-- TOC entry 5552 (class 0 OID 17298)
-- Dependencies: 242
-- Data for Name: room_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.room_type (room_type_id, name, capacity, daily_rate, amenities) FROM stdin;
1	Standard Single	1	12000.00	WiFi, TV, AC
2	Standard Double	2	18000.00	WiFi, TV, AC, Mini Fridge
3	Deluxe King	2	24000.00	WiFi, TV, AC, Mini Bar, Sea View
4	Suite	4	40000.00	WiFi, TV, AC, Mini Bar, Kitchenette, Balcony
\.


--
-- TOC entry 5554 (class 0 OID 17308)
-- Dependencies: 244
-- Data for Name: service_catalog; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.service_catalog (service_id, code, name, category, unit_price, tax_rate_percent, active) FROM stdin;
1	BRK	Breakfast Buffet	Food & Beverage	2500.00	0.00	t
2	DIN	Dinner (Set Menu)	Food & Beverage	6000.00	0.00	t
3	RMS	Room Service	Food & Beverage	3500.00	0.00	t
4	MIN	Minibar (per item)	Food & Beverage	1800.00	0.00	t
5	SPA	Spa Treatment (60m)	Wellness	15000.00	0.00	t
6	LND	Laundry (per piece)	Housekeeping	600.00	0.00	t
7	TRN	Airport Transfer	Transport	12000.00	0.00	t
\.


--
-- TOC entry 5556 (class 0 OID 17319)
-- Dependencies: 246
-- Data for Name: service_usage; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.service_usage (service_usage_id, booking_id, service_id, used_on, qty, unit_price_at_use) FROM stdin;
1	1	5	2025-07-02	2	15000.00
2	1	1	2025-07-02	2	2500.00
3	3	6	2025-07-12	3	600.00
4	3	3	2025-07-09	3	3500.00
5	4	3	2025-07-16	2	3500.00
6	5	3	2025-07-24	2	3500.00
7	5	1	2025-07-25	4	2500.00
8	5	1	2025-07-23	1	2500.00
9	5	1	2025-07-23	2	2500.00
10	6	4	2025-07-28	1	1800.00
11	6	2	2025-07-26	2	6000.00
12	6	4	2025-07-28	2	1800.00
13	7	3	2025-08-02	1	3500.00
14	8	7	2025-08-06	2	12000.00
15	8	5	2025-08-07	3	15000.00
16	10	7	2025-08-13	2	12000.00
17	10	5	2025-08-15	4	15000.00
18	10	7	2025-08-14	4	12000.00
19	10	7	2025-08-13	4	12000.00
20	13	4	2025-08-29	3	1800.00
21	15	5	2025-09-03	1	15000.00
22	15	2	2025-09-01	2	6000.00
23	15	4	2025-09-01	1	1800.00
24	17	5	2025-09-12	3	15000.00
25	17	3	2025-09-11	2	3500.00
26	17	3	2025-09-13	3	3500.00
27	17	7	2025-09-14	1	12000.00
28	19	2	2025-09-20	1	6000.00
29	19	1	2025-09-20	4	2500.00
30	19	3	2025-09-20	3	3500.00
31	19	7	2025-09-20	3	12000.00
32	20	2	2025-09-24	1	6000.00
33	21	7	2025-09-28	4	12000.00
34	21	4	2025-09-29	2	1800.00
35	23	3	2025-07-04	4	3500.00
36	23	7	2025-07-07	2	12000.00
37	24	2	2025-07-11	3	6000.00
38	24	5	2025-07-10	2	15000.00
39	25	6	2025-07-13	2	600.00
40	25	4	2025-07-13	2	1800.00
41	25	2	2025-07-14	3	6000.00
42	25	1	2025-07-15	2	2500.00
43	28	6	2025-07-25	2	600.00
44	28	5	2025-07-26	2	15000.00
45	28	1	2025-07-26	1	2500.00
46	29	4	2025-07-28	2	1800.00
47	31	2	2025-08-04	3	6000.00
48	31	2	2025-08-04	1	6000.00
49	32	2	2025-08-06	3	6000.00
50	32	4	2025-08-08	3	1800.00
51	33	4	2025-08-11	4	1800.00
52	33	3	2025-08-12	3	3500.00
53	33	2	2025-08-12	2	6000.00
54	34	7	2025-08-15	3	12000.00
55	34	5	2025-08-15	2	15000.00
56	34	1	2025-08-13	3	2500.00
57	35	1	2025-08-20	1	2500.00
58	35	4	2025-08-20	2	1800.00
59	37	5	2025-08-26	2	15000.00
60	38	1	2025-09-01	2	2500.00
61	38	1	2025-08-31	2	2500.00
62	39	7	2025-09-05	3	12000.00
63	39	4	2025-09-05	3	1800.00
64	39	7	2025-09-04	2	12000.00
65	40	2	2025-09-09	3	6000.00
66	41	1	2025-09-12	1	2500.00
67	41	2	2025-09-13	2	6000.00
68	41	5	2025-09-14	2	15000.00
69	42	5	2025-09-17	3	15000.00
70	42	5	2025-09-17	1	15000.00
71	43	3	2025-09-19	2	3500.00
72	43	6	2025-09-19	2	600.00
73	43	5	2025-09-19	3	15000.00
74	43	7	2025-09-20	3	12000.00
75	44	5	2025-09-23	4	15000.00
76	44	5	2025-09-23	4	15000.00
77	44	4	2025-09-23	1	1800.00
78	44	7	2025-09-24	3	12000.00
79	45	3	2025-09-27	4	3500.00
80	45	5	2025-09-26	3	15000.00
81	46	5	2025-10-02	2	15000.00
82	46	6	2025-10-01	4	600.00
83	46	4	2025-10-01	3	1800.00
84	48	5	2025-07-06	4	15000.00
85	48	7	2025-07-07	3	12000.00
86	49	4	2025-07-10	1	1800.00
87	49	3	2025-07-10	1	3500.00
88	49	5	2025-07-10	1	15000.00
89	50	3	2025-07-13	3	3500.00
90	50	3	2025-07-13	4	3500.00
91	50	7	2025-07-14	1	12000.00
92	50	4	2025-07-12	4	1800.00
93	51	1	2025-07-16	4	2500.00
94	51	2	2025-07-15	4	6000.00
95	52	7	2025-07-21	3	12000.00
96	53	3	2025-07-24	2	3500.00
97	54	6	2025-07-28	1	600.00
98	54	5	2025-07-28	2	15000.00
99	54	4	2025-07-29	4	1800.00
100	55	2	2025-08-03	1	6000.00
101	56	1	2025-08-06	2	2500.00
102	56	7	2025-08-06	4	12000.00
103	57	6	2025-08-08	2	600.00
104	58	3	2025-08-14	3	3500.00
105	58	1	2025-08-13	3	2500.00
106	60	7	2025-08-23	3	12000.00
107	60	1	2025-08-23	2	2500.00
108	60	6	2025-08-22	4	600.00
109	63	4	2025-09-03	3	1800.00
110	63	3	2025-09-04	3	3500.00
111	63	5	2025-09-04	3	15000.00
112	63	5	2025-09-03	4	15000.00
113	64	4	2025-09-09	3	1800.00
114	64	4	2025-09-06	4	1800.00
115	65	1	2025-09-12	3	2500.00
116	65	3	2025-09-10	3	3500.00
117	65	6	2025-09-13	3	600.00
118	66	7	2025-09-17	4	12000.00
119	67	3	2025-09-23	2	3500.00
120	67	7	2025-09-23	1	12000.00
121	68	3	2025-09-26	1	3500.00
122	68	5	2025-09-26	2	15000.00
123	68	7	2025-09-26	2	12000.00
124	69	3	2025-09-30	4	3500.00
125	69	5	2025-09-28	2	15000.00
126	69	1	2025-09-29	1	2500.00
127	69	5	2025-09-30	4	15000.00
128	71	3	2025-07-06	3	3500.00
129	71	5	2025-07-06	2	15000.00
130	71	5	2025-07-05	4	15000.00
131	72	6	2025-07-10	3	600.00
132	72	4	2025-07-10	2	1800.00
133	72	5	2025-07-10	1	15000.00
134	73	7	2025-07-13	2	12000.00
135	73	2	2025-07-12	2	6000.00
136	73	5	2025-07-13	4	15000.00
137	74	3	2025-07-14	3	3500.00
138	74	4	2025-07-14	3	1800.00
139	74	7	2025-07-14	4	12000.00
140	74	5	2025-07-14	2	15000.00
141	75	7	2025-07-17	3	12000.00
142	75	6	2025-07-17	1	600.00
143	75	4	2025-07-16	1	1800.00
144	75	3	2025-07-17	4	3500.00
145	76	4	2025-07-19	2	1800.00
146	76	4	2025-07-19	2	1800.00
147	77	1	2025-07-22	4	2500.00
148	79	4	2025-07-31	2	1800.00
149	79	3	2025-07-31	2	3500.00
150	79	5	2025-07-31	1	15000.00
151	79	3	2025-07-31	2	3500.00
152	80	1	2025-08-04	2	2500.00
153	80	4	2025-08-04	4	1800.00
154	80	7	2025-08-05	2	12000.00
155	81	5	2025-08-09	4	15000.00
156	81	6	2025-08-09	4	600.00
157	82	4	2025-08-13	2	1800.00
158	83	4	2025-08-18	2	1800.00
159	83	6	2025-08-17	3	600.00
160	83	1	2025-08-17	4	2500.00
161	83	1	2025-08-17	1	2500.00
162	85	7	2025-08-24	4	12000.00
163	85	6	2025-08-24	4	600.00
164	85	4	2025-08-24	3	1800.00
165	86	6	2025-08-27	4	600.00
166	86	4	2025-08-25	2	1800.00
167	86	1	2025-08-29	3	2500.00
168	86	2	2025-08-29	1	6000.00
169	87	7	2025-09-01	4	12000.00
170	87	5	2025-09-01	2	15000.00
171	88	5	2025-09-05	2	15000.00
172	88	3	2025-09-05	2	3500.00
173	88	4	2025-09-07	3	1800.00
174	89	5	2025-09-11	2	15000.00
175	89	1	2025-09-10	2	2500.00
176	90	1	2025-09-18	4	2500.00
177	90	5	2025-09-15	1	15000.00
178	91	4	2025-09-19	2	1800.00
179	91	4	2025-09-19	3	1800.00
180	91	5	2025-09-19	1	15000.00
181	91	5	2025-09-19	1	15000.00
182	92	1	2025-09-25	3	2500.00
183	92	2	2025-09-22	2	6000.00
184	92	5	2025-09-26	3	15000.00
185	93	5	2025-09-28	4	15000.00
186	93	3	2025-09-28	3	3500.00
187	94	4	2025-07-01	3	1800.00
188	95	7	2025-07-06	3	12000.00
189	95	1	2025-07-07	2	2500.00
190	95	6	2025-07-06	1	600.00
191	96	5	2025-07-09	3	15000.00
192	96	4	2025-07-10	2	1800.00
193	97	4	2025-07-14	2	1800.00
194	97	2	2025-07-13	2	6000.00
195	97	4	2025-07-13	2	1800.00
196	98	3	2025-07-19	2	3500.00
197	98	7	2025-07-19	1	12000.00
198	98	1	2025-07-19	3	2500.00
199	98	2	2025-07-19	3	6000.00
200	99	4	2025-07-21	2	1800.00
201	99	5	2025-07-21	4	15000.00
202	99	2	2025-07-21	3	6000.00
203	100	7	2025-07-23	3	12000.00
204	100	7	2025-07-23	3	12000.00
205	101	7	2025-07-25	1	12000.00
206	101	2	2025-07-25	1	6000.00
207	101	7	2025-07-26	2	12000.00
208	102	2	2025-07-30	3	6000.00
209	102	4	2025-07-31	4	1800.00
210	102	1	2025-07-31	3	2500.00
211	103	7	2025-08-06	3	12000.00
212	104	4	2025-08-13	2	1800.00
213	104	6	2025-08-10	3	600.00
214	104	1	2025-08-12	4	2500.00
215	105	6	2025-08-17	4	600.00
216	105	1	2025-08-17	1	2500.00
217	106	2	2025-08-20	3	6000.00
218	106	6	2025-08-19	3	600.00
219	106	2	2025-08-19	2	6000.00
220	108	7	2025-08-30	4	12000.00
221	108	2	2025-08-27	4	6000.00
222	108	7	2025-08-27	2	12000.00
223	109	5	2025-08-31	2	15000.00
224	109	5	2025-08-31	1	15000.00
225	110	2	2025-09-03	3	6000.00
226	110	4	2025-09-03	2	1800.00
227	110	5	2025-09-04	1	15000.00
228	111	6	2025-09-07	2	600.00
229	112	5	2025-09-11	3	15000.00
230	112	1	2025-09-11	4	2500.00
231	112	7	2025-09-11	2	12000.00
232	113	1	2025-09-13	1	2500.00
233	113	7	2025-09-14	1	12000.00
234	113	1	2025-09-14	3	2500.00
235	115	6	2025-09-23	3	600.00
236	115	7	2025-09-24	2	12000.00
237	115	2	2025-09-24	1	6000.00
238	115	7	2025-09-23	3	12000.00
239	117	2	2025-07-02	4	6000.00
240	117	5	2025-07-02	1	15000.00
241	117	7	2025-07-02	3	12000.00
242	119	5	2025-07-09	2	15000.00
243	119	3	2025-07-09	4	3500.00
244	119	3	2025-07-07	1	3500.00
245	120	6	2025-07-10	1	600.00
246	120	3	2025-07-10	1	3500.00
247	122	1	2025-07-21	1	2500.00
248	122	7	2025-07-19	1	12000.00
249	122	2	2025-07-20	3	6000.00
250	122	2	2025-07-19	3	6000.00
251	123	5	2025-07-28	3	15000.00
252	124	5	2025-07-30	2	15000.00
253	125	4	2025-07-31	2	1800.00
254	126	3	2025-08-02	1	3500.00
255	126	7	2025-08-02	3	12000.00
256	126	1	2025-08-03	4	2500.00
257	127	6	2025-08-06	2	600.00
258	128	7	2025-08-09	1	12000.00
259	128	6	2025-08-11	1	600.00
260	128	5	2025-08-09	1	15000.00
261	129	1	2025-08-15	3	2500.00
262	129	3	2025-08-15	3	3500.00
263	129	7	2025-08-14	2	12000.00
264	129	7	2025-08-14	3	12000.00
265	130	5	2025-08-19	3	15000.00
266	130	6	2025-08-20	2	600.00
267	132	7	2025-08-26	4	12000.00
268	133	5	2025-08-29	1	15000.00
269	135	5	2025-09-05	3	15000.00
270	135	3	2025-09-05	2	3500.00
271	135	3	2025-09-04	3	3500.00
272	135	1	2025-09-05	1	2500.00
273	136	6	2025-09-07	2	600.00
274	136	4	2025-09-07	3	1800.00
275	136	3	2025-09-07	2	3500.00
276	136	7	2025-09-08	3	12000.00
277	137	6	2025-09-11	1	600.00
278	137	2	2025-09-11	2	6000.00
279	137	1	2025-09-11	2	2500.00
280	137	5	2025-09-11	2	15000.00
281	138	4	2025-09-12	4	1800.00
282	138	7	2025-09-12	3	12000.00
283	138	6	2025-09-12	3	600.00
284	140	1	2025-09-22	3	2500.00
285	141	7	2025-09-27	2	12000.00
286	141	2	2025-09-27	3	6000.00
287	141	7	2025-09-26	2	12000.00
288	143	1	2025-10-01	2	2500.00
289	143	4	2025-10-01	2	1800.00
290	143	1	2025-10-02	3	2500.00
291	144	6	2025-07-02	2	600.00
292	145	2	2025-07-06	4	6000.00
293	146	6	2025-07-12	4	600.00
294	146	3	2025-07-12	4	3500.00
295	146	6	2025-07-12	2	600.00
296	147	1	2025-07-15	4	2500.00
297	148	3	2025-07-18	3	3500.00
298	148	4	2025-07-21	3	1800.00
299	149	3	2025-07-24	1	3500.00
300	150	7	2025-08-01	1	12000.00
301	150	1	2025-07-31	2	2500.00
302	150	5	2025-07-30	1	15000.00
303	151	5	2025-08-04	4	15000.00
304	151	3	2025-08-04	3	3500.00
305	151	4	2025-08-04	2	1800.00
306	153	5	2025-08-11	4	15000.00
307	153	2	2025-08-11	4	6000.00
308	153	6	2025-08-11	2	600.00
309	154	1	2025-08-12	4	2500.00
310	154	2	2025-08-12	1	6000.00
311	154	7	2025-08-12	3	12000.00
312	154	5	2025-08-12	2	15000.00
313	155	5	2025-08-13	3	15000.00
314	155	4	2025-08-14	2	1800.00
315	155	4	2025-08-14	3	1800.00
316	155	6	2025-08-14	3	600.00
317	157	2	2025-08-22	3	6000.00
318	157	7	2025-08-20	4	12000.00
319	157	2	2025-08-21	2	6000.00
320	157	2	2025-08-20	3	6000.00
321	158	4	2025-08-24	4	1800.00
322	158	1	2025-08-25	3	2500.00
323	158	7	2025-08-24	1	12000.00
324	159	1	2025-08-28	1	2500.00
325	159	4	2025-08-27	2	1800.00
326	160	5	2025-09-01	1	15000.00
327	161	6	2025-09-07	3	600.00
328	161	7	2025-09-08	2	12000.00
329	162	3	2025-09-14	2	3500.00
330	162	1	2025-09-12	2	2500.00
331	162	3	2025-09-14	3	3500.00
332	163	5	2025-09-19	2	15000.00
333	163	4	2025-09-21	4	1800.00
334	163	5	2025-09-20	2	15000.00
335	164	7	2025-09-23	2	12000.00
336	165	2	2025-09-26	3	6000.00
337	165	1	2025-09-27	3	2500.00
338	165	4	2025-09-28	1	1800.00
339	166	7	2025-09-30	2	12000.00
340	166	4	2025-10-02	1	1800.00
341	168	5	2025-07-06	1	15000.00
342	168	2	2025-07-08	2	6000.00
343	169	7	2025-07-11	3	12000.00
344	169	3	2025-07-11	2	3500.00
345	169	5	2025-07-11	1	15000.00
346	170	6	2025-07-15	3	600.00
347	170	7	2025-07-14	2	12000.00
348	170	5	2025-07-14	3	15000.00
349	170	3	2025-07-15	2	3500.00
350	171	2	2025-07-19	3	6000.00
351	172	4	2025-07-25	4	1800.00
352	172	4	2025-07-24	1	1800.00
353	173	6	2025-07-26	1	600.00
354	173	4	2025-07-26	3	1800.00
355	174	7	2025-07-28	3	12000.00
356	174	1	2025-07-29	2	2500.00
357	174	6	2025-07-29	3	600.00
358	176	3	2025-08-06	1	3500.00
359	176	1	2025-08-06	4	2500.00
360	177	3	2025-08-09	2	3500.00
361	178	4	2025-08-16	1	1800.00
362	179	7	2025-08-22	2	12000.00
363	179	6	2025-08-21	1	600.00
364	179	4	2025-08-23	3	1800.00
365	180	2	2025-08-25	1	6000.00
366	180	7	2025-08-26	2	12000.00
367	180	3	2025-08-26	1	3500.00
368	181	4	2025-08-27	1	1800.00
369	181	1	2025-08-27	3	2500.00
370	181	1	2025-08-27	1	2500.00
371	182	7	2025-08-31	3	12000.00
372	182	1	2025-08-31	2	2500.00
373	182	5	2025-08-30	2	15000.00
374	183	7	2025-09-04	2	12000.00
375	184	5	2025-09-06	1	15000.00
376	185	4	2025-09-09	2	1800.00
377	185	1	2025-09-11	1	2500.00
378	185	6	2025-09-12	1	600.00
379	187	2	2025-09-18	2	6000.00
380	187	3	2025-09-17	3	3500.00
381	187	3	2025-09-18	4	3500.00
382	188	4	2025-09-24	2	1800.00
383	188	1	2025-09-23	4	2500.00
384	189	4	2025-09-28	1	1800.00
385	189	7	2025-09-27	3	12000.00
386	190	2	2025-07-03	2	6000.00
387	191	6	2025-07-08	1	600.00
388	192	2	2025-07-12	2	6000.00
389	192	1	2025-07-12	1	2500.00
390	192	7	2025-07-12	3	12000.00
391	193	4	2025-07-14	4	1800.00
392	193	5	2025-07-14	3	15000.00
393	194	4	2025-07-15	1	1800.00
394	196	4	2025-07-26	3	1800.00
395	197	2	2025-07-30	1	6000.00
396	198	5	2025-08-03	3	15000.00
397	198	6	2025-08-01	3	600.00
398	198	3	2025-08-03	1	3500.00
399	198	6	2025-08-02	2	600.00
400	199	7	2025-08-09	3	12000.00
401	199	5	2025-08-10	3	15000.00
402	199	2	2025-08-07	4	6000.00
403	200	6	2025-08-13	1	600.00
404	200	2	2025-08-16	2	6000.00
405	200	3	2025-08-12	3	3500.00
406	200	1	2025-08-13	4	2500.00
407	201	2	2025-08-19	1	6000.00
408	202	7	2025-08-25	3	12000.00
409	202	1	2025-08-22	1	2500.00
410	203	7	2025-08-28	2	12000.00
411	204	2	2025-09-03	4	6000.00
412	204	3	2025-09-02	3	3500.00
413	205	7	2025-09-08	1	12000.00
414	205	1	2025-09-04	3	2500.00
415	206	6	2025-09-09	3	600.00
416	206	6	2025-09-09	2	600.00
417	207	1	2025-09-10	2	2500.00
418	207	5	2025-09-12	3	15000.00
419	207	1	2025-09-10	2	2500.00
420	207	2	2025-09-12	2	6000.00
421	208	1	2025-09-17	4	2500.00
422	208	1	2025-09-17	1	2500.00
423	208	5	2025-09-17	4	15000.00
424	208	3	2025-09-17	1	3500.00
425	210	1	2025-09-27	2	2500.00
426	210	2	2025-09-27	1	6000.00
427	210	5	2025-09-28	2	15000.00
428	211	2	2025-07-04	2	6000.00
429	211	1	2025-07-03	4	2500.00
430	211	2	2025-07-03	4	6000.00
431	212	7	2025-07-07	3	12000.00
432	214	1	2025-07-16	2	2500.00
433	214	1	2025-07-16	4	2500.00
434	215	1	2025-07-19	2	2500.00
435	216	2	2025-07-24	2	6000.00
436	216	6	2025-07-23	4	600.00
437	217	1	2025-07-26	4	2500.00
438	217	5	2025-07-27	3	15000.00
439	218	4	2025-07-30	3	1800.00
440	218	5	2025-07-30	3	15000.00
441	218	7	2025-07-30	2	12000.00
442	218	4	2025-07-30	2	1800.00
443	219	3	2025-08-02	3	3500.00
444	221	7	2025-08-09	3	12000.00
445	221	6	2025-08-07	3	600.00
446	221	1	2025-08-09	4	2500.00
447	222	2	2025-08-12	2	6000.00
448	222	6	2025-08-12	3	600.00
449	222	5	2025-08-12	2	15000.00
450	222	5	2025-08-11	4	15000.00
451	223	5	2025-08-15	3	15000.00
452	223	5	2025-08-15	2	15000.00
453	223	3	2025-08-14	2	3500.00
454	226	2	2025-08-23	2	6000.00
455	226	5	2025-08-23	2	15000.00
456	226	7	2025-08-24	4	12000.00
457	227	2	2025-08-26	4	6000.00
458	227	6	2025-08-25	3	600.00
459	227	2	2025-08-26	3	6000.00
460	227	5	2025-08-25	3	15000.00
461	228	5	2025-08-28	2	15000.00
462	228	5	2025-08-28	3	15000.00
463	228	4	2025-08-29	3	1800.00
464	228	1	2025-08-28	4	2500.00
465	229	4	2025-09-01	2	1800.00
466	230	7	2025-09-04	1	12000.00
467	231	3	2025-09-06	3	3500.00
468	231	3	2025-09-10	3	3500.00
469	231	3	2025-09-08	4	3500.00
470	232	4	2025-09-11	2	1800.00
471	232	6	2025-09-11	2	600.00
472	233	5	2025-09-15	2	15000.00
473	233	3	2025-09-13	4	3500.00
474	235	2	2025-09-21	4	6000.00
475	236	4	2025-09-26	3	1800.00
476	237	2	2025-09-29	3	6000.00
477	239	2	2025-07-06	2	6000.00
478	239	7	2025-07-06	1	12000.00
479	241	2	2025-07-15	3	6000.00
480	244	7	2025-07-31	4	12000.00
481	244	4	2025-07-27	3	1800.00
482	244	5	2025-07-29	4	15000.00
483	245	4	2025-08-02	1	1800.00
484	245	5	2025-08-02	4	15000.00
485	246	2	2025-08-03	4	6000.00
486	246	3	2025-08-03	2	3500.00
487	246	1	2025-08-03	3	2500.00
488	247	5	2025-08-07	3	15000.00
489	247	5	2025-08-08	2	15000.00
490	248	3	2025-08-11	2	3500.00
491	248	4	2025-08-11	3	1800.00
492	249	2	2025-08-13	1	6000.00
493	249	6	2025-08-14	3	600.00
494	250	7	2025-08-16	4	12000.00
495	250	4	2025-08-16	3	1800.00
496	251	7	2025-08-20	4	12000.00
497	251	6	2025-08-19	4	600.00
498	251	3	2025-08-18	3	3500.00
499	252	5	2025-08-22	3	15000.00
500	253	2	2025-08-28	4	6000.00
501	253	6	2025-08-27	3	600.00
502	254	1	2025-08-30	3	2500.00
503	255	2	2025-09-06	1	6000.00
504	255	2	2025-09-06	4	6000.00
505	256	5	2025-09-11	1	15000.00
506	256	2	2025-09-08	3	6000.00
507	256	1	2025-09-09	2	2500.00
508	256	6	2025-09-09	4	600.00
509	257	6	2025-09-16	3	600.00
510	258	3	2025-09-20	3	3500.00
511	258	2	2025-09-20	3	6000.00
512	258	5	2025-09-19	3	15000.00
513	259	4	2025-09-24	2	1800.00
514	260	2	2025-09-26	2	6000.00
515	260	3	2025-09-27	3	3500.00
516	261	7	2025-10-01	1	12000.00
517	261	1	2025-09-30	2	2500.00
518	261	7	2025-10-02	1	12000.00
519	262	3	2025-07-02	1	3500.00
520	262	5	2025-07-01	4	15000.00
521	262	1	2025-07-01	4	2500.00
522	264	4	2025-07-10	3	1800.00
523	264	5	2025-07-10	3	15000.00
524	264	2	2025-07-10	2	6000.00
525	264	5	2025-07-11	3	15000.00
526	265	7	2025-07-13	2	12000.00
527	265	3	2025-07-12	2	3500.00
528	265	2	2025-07-12	3	6000.00
529	266	3	2025-07-16	3	3500.00
530	266	2	2025-07-16	2	6000.00
531	266	6	2025-07-15	1	600.00
532	267	6	2025-07-19	1	600.00
533	267	6	2025-07-20	3	600.00
534	267	6	2025-07-22	2	600.00
535	267	1	2025-07-19	3	2500.00
536	268	5	2025-07-26	3	15000.00
537	268	4	2025-07-26	4	1800.00
538	268	5	2025-07-24	2	15000.00
539	269	2	2025-07-29	1	6000.00
540	269	4	2025-07-30	3	1800.00
541	271	1	2025-08-07	2	2500.00
542	271	1	2025-08-06	3	2500.00
543	271	5	2025-08-06	1	15000.00
544	271	1	2025-08-06	4	2500.00
545	272	4	2025-08-11	2	1800.00
546	272	4	2025-08-11	2	1800.00
547	272	6	2025-08-11	1	600.00
548	273	5	2025-08-13	1	15000.00
549	273	4	2025-08-13	2	1800.00
550	275	2	2025-08-20	2	6000.00
551	275	1	2025-08-20	2	2500.00
552	275	2	2025-08-19	4	6000.00
553	276	3	2025-08-26	4	3500.00
554	277	7	2025-08-28	1	12000.00
555	277	7	2025-08-28	2	12000.00
556	277	6	2025-08-27	2	600.00
557	277	4	2025-08-27	3	1800.00
558	278	3	2025-08-29	1	3500.00
559	280	2	2025-09-07	3	6000.00
560	280	3	2025-09-06	2	3500.00
561	280	4	2025-09-06	3	1800.00
562	281	5	2025-09-12	3	15000.00
563	281	2	2025-09-11	2	6000.00
564	281	1	2025-09-12	2	2500.00
565	284	3	2025-09-27	1	3500.00
566	284	5	2025-09-27	1	15000.00
567	285	3	2025-09-30	3	3500.00
568	285	1	2025-10-01	3	2500.00
569	285	5	2025-09-30	4	15000.00
570	285	1	2025-10-02	2	2500.00
571	286	5	2025-07-01	4	15000.00
572	286	4	2025-07-01	4	1800.00
573	286	2	2025-07-01	2	6000.00
574	287	1	2025-07-05	1	2500.00
575	288	2	2025-07-10	3	6000.00
576	288	7	2025-07-09	4	12000.00
577	289	2	2025-07-13	2	6000.00
578	290	6	2025-07-17	2	600.00
579	290	3	2025-07-16	2	3500.00
580	292	1	2025-07-28	3	2500.00
581	292	2	2025-07-26	2	6000.00
582	292	1	2025-07-27	2	2500.00
583	293	1	2025-08-02	2	2500.00
584	293	2	2025-08-03	2	6000.00
585	293	4	2025-08-02	1	1800.00
586	293	2	2025-08-02	2	6000.00
587	295	4	2025-08-11	2	1800.00
588	295	3	2025-08-13	2	3500.00
589	295	3	2025-08-11	1	3500.00
590	296	6	2025-08-18	3	600.00
591	296	3	2025-08-18	3	3500.00
592	297	4	2025-08-19	4	1800.00
593	297	6	2025-08-20	4	600.00
594	297	5	2025-08-20	3	15000.00
595	297	6	2025-08-20	2	600.00
596	299	1	2025-08-28	3	2500.00
597	299	2	2025-08-28	3	6000.00
598	300	7	2025-08-30	1	12000.00
599	302	6	2025-09-09	2	600.00
600	302	6	2025-09-09	3	600.00
601	302	6	2025-09-07	1	600.00
602	303	7	2025-09-10	2	12000.00
603	303	1	2025-09-11	1	2500.00
604	304	6	2025-09-18	2	600.00
605	305	1	2025-09-24	2	2500.00
606	306	6	2025-09-27	1	600.00
607	307	3	2025-10-01	4	3500.00
608	308	7	2025-07-02	2	12000.00
609	309	1	2025-07-09	1	2500.00
610	309	1	2025-07-09	1	2500.00
611	309	6	2025-07-10	3	600.00
612	310	7	2025-07-12	1	12000.00
613	310	2	2025-07-11	1	6000.00
614	311	2	2025-07-18	3	6000.00
615	311	1	2025-07-16	3	2500.00
616	311	2	2025-07-18	1	6000.00
617	312	3	2025-07-23	2	3500.00
618	312	7	2025-07-23	4	12000.00
619	312	5	2025-07-22	1	15000.00
620	312	3	2025-07-22	3	3500.00
621	313	5	2025-07-27	3	15000.00
622	313	5	2025-07-27	2	15000.00
623	313	7	2025-07-27	2	12000.00
624	314	2	2025-08-01	4	6000.00
625	315	2	2025-08-06	3	6000.00
626	316	7	2025-08-11	2	12000.00
627	316	5	2025-08-12	1	15000.00
628	316	6	2025-08-11	1	600.00
629	316	7	2025-08-11	2	12000.00
630	317	5	2025-08-15	1	15000.00
631	317	5	2025-08-14	1	15000.00
632	317	4	2025-08-15	2	1800.00
633	317	4	2025-08-13	3	1800.00
634	318	4	2025-08-20	4	1800.00
635	318	1	2025-08-20	3	2500.00
636	318	3	2025-08-20	3	3500.00
637	318	1	2025-08-19	3	2500.00
638	319	1	2025-08-25	1	2500.00
639	320	7	2025-08-29	3	12000.00
640	320	6	2025-08-28	3	600.00
641	320	5	2025-08-27	1	15000.00
642	320	4	2025-08-28	2	1800.00
643	321	2	2025-09-02	3	6000.00
644	322	7	2025-09-07	3	12000.00
645	322	5	2025-09-08	2	15000.00
646	322	3	2025-09-07	4	3500.00
647	323	6	2025-09-13	1	600.00
648	323	7	2025-09-13	1	12000.00
649	323	2	2025-09-13	4	6000.00
650	324	4	2025-09-18	2	1800.00
651	325	3	2025-09-20	4	3500.00
652	325	4	2025-09-23	3	1800.00
653	325	6	2025-09-20	4	600.00
654	325	5	2025-09-23	3	15000.00
655	326	5	2025-09-27	3	15000.00
656	327	7	2025-10-01	2	12000.00
657	327	3	2025-09-30	3	3500.00
658	328	3	2025-07-02	3	3500.00
659	328	2	2025-07-01	2	6000.00
660	328	4	2025-07-01	3	1800.00
661	328	4	2025-07-02	2	1800.00
662	329	1	2025-07-06	4	2500.00
663	330	6	2025-07-11	1	600.00
664	330	6	2025-07-09	3	600.00
665	330	4	2025-07-09	2	1800.00
666	330	7	2025-07-10	4	12000.00
667	331	6	2025-07-16	2	600.00
668	332	3	2025-07-20	3	3500.00
669	332	6	2025-07-20	4	600.00
670	332	7	2025-07-20	1	12000.00
671	332	1	2025-07-21	2	2500.00
672	333	4	2025-07-24	2	1800.00
673	333	1	2025-07-25	2	2500.00
674	333	5	2025-07-24	1	15000.00
675	334	4	2025-07-27	4	1800.00
676	334	4	2025-07-27	3	1800.00
677	334	2	2025-07-27	3	6000.00
678	334	4	2025-07-27	2	1800.00
679	335	7	2025-07-30	1	12000.00
680	335	5	2025-07-30	1	15000.00
681	335	6	2025-07-30	2	600.00
682	336	6	2025-08-02	3	600.00
683	336	3	2025-08-03	3	3500.00
684	337	7	2025-08-07	3	12000.00
685	337	4	2025-08-07	3	1800.00
686	337	4	2025-08-07	1	1800.00
687	337	5	2025-08-07	4	15000.00
688	338	2	2025-08-08	4	6000.00
689	338	5	2025-08-09	3	15000.00
690	338	5	2025-08-09	3	15000.00
691	338	7	2025-08-09	1	12000.00
692	339	3	2025-08-10	3	3500.00
693	339	7	2025-08-10	2	12000.00
694	340	2	2025-08-14	4	6000.00
695	340	2	2025-08-14	2	6000.00
696	340	2	2025-08-14	1	6000.00
697	341	2	2025-08-18	1	6000.00
698	341	1	2025-08-18	4	2500.00
699	341	4	2025-08-17	3	1800.00
700	341	7	2025-08-18	1	12000.00
701	342	4	2025-08-22	2	1800.00
702	342	7	2025-08-22	2	12000.00
703	342	6	2025-08-22	3	600.00
704	342	7	2025-08-22	1	12000.00
705	343	1	2025-08-24	3	2500.00
706	343	2	2025-08-25	3	6000.00
707	343	2	2025-08-25	2	6000.00
708	344	5	2025-08-28	3	15000.00
709	344	3	2025-08-29	1	3500.00
710	345	5	2025-09-03	4	15000.00
711	345	5	2025-09-03	1	15000.00
712	345	6	2025-09-04	3	600.00
713	346	6	2025-09-07	2	600.00
714	346	7	2025-09-08	1	12000.00
715	346	2	2025-09-07	1	6000.00
716	347	6	2025-09-12	3	600.00
717	347	4	2025-09-11	2	1800.00
718	347	2	2025-09-13	3	6000.00
719	347	5	2025-09-14	1	15000.00
720	348	1	2025-09-16	3	2500.00
721	349	4	2025-09-18	4	1800.00
722	350	2	2025-09-23	3	6000.00
723	350	1	2025-09-23	1	2500.00
724	351	7	2025-09-25	2	12000.00
725	351	1	2025-09-24	1	2500.00
726	351	6	2025-09-25	2	600.00
727	352	7	2025-09-27	1	12000.00
728	352	1	2025-09-27	4	2500.00
729	352	3	2025-09-28	4	3500.00
730	352	6	2025-09-27	4	600.00
731	353	2	2025-09-30	2	6000.00
732	354	5	2025-07-02	2	15000.00
733	354	3	2025-07-02	2	3500.00
734	355	2	2025-07-06	3	6000.00
735	355	7	2025-07-05	3	12000.00
736	355	4	2025-07-06	1	1800.00
737	355	3	2025-07-06	1	3500.00
738	356	6	2025-07-11	3	600.00
739	356	3	2025-07-09	2	3500.00
740	356	6	2025-07-08	2	600.00
741	356	4	2025-07-10	4	1800.00
742	357	6	2025-07-12	4	600.00
743	357	6	2025-07-12	3	600.00
744	357	4	2025-07-12	3	1800.00
745	357	4	2025-07-13	1	1800.00
746	358	7	2025-07-16	2	12000.00
747	359	1	2025-07-21	1	2500.00
748	360	1	2025-07-26	2	2500.00
749	360	3	2025-07-24	4	3500.00
750	360	7	2025-07-23	4	12000.00
751	361	2	2025-07-30	3	6000.00
752	361	3	2025-07-30	1	3500.00
753	361	1	2025-07-29	3	2500.00
754	363	4	2025-08-04	3	1800.00
755	364	1	2025-08-08	2	2500.00
756	365	6	2025-08-13	2	600.00
757	365	1	2025-08-13	1	2500.00
758	365	5	2025-08-12	3	15000.00
759	365	6	2025-08-13	2	600.00
760	366	6	2025-08-15	4	600.00
761	366	6	2025-08-15	2	600.00
762	367	3	2025-08-17	3	3500.00
763	368	7	2025-08-25	4	12000.00
764	369	1	2025-08-27	1	2500.00
765	369	2	2025-08-28	3	6000.00
766	371	5	2025-09-05	1	15000.00
767	371	7	2025-09-06	4	12000.00
768	373	3	2025-09-13	3	3500.00
769	373	2	2025-09-12	4	6000.00
770	374	3	2025-09-15	2	3500.00
771	375	1	2025-09-20	3	2500.00
772	376	1	2025-09-23	4	2500.00
773	377	6	2025-09-26	2	600.00
774	378	2	2025-09-30	2	6000.00
775	378	4	2025-09-30	2	1800.00
776	379	4	2025-07-01	3	1800.00
777	381	4	2025-07-06	2	1800.00
778	381	4	2025-07-07	3	1800.00
779	381	4	2025-07-06	2	1800.00
780	382	2	2025-07-12	2	6000.00
781	383	1	2025-07-16	2	2500.00
782	384	4	2025-07-20	3	1800.00
783	384	4	2025-07-19	2	1800.00
784	385	1	2025-07-24	2	2500.00
785	385	2	2025-07-24	3	6000.00
786	386	2	2025-07-28	1	6000.00
787	386	2	2025-07-29	3	6000.00
788	386	7	2025-07-27	2	12000.00
789	388	4	2025-08-10	4	1800.00
790	388	4	2025-08-08	2	1800.00
791	389	5	2025-08-11	2	15000.00
792	389	5	2025-08-11	2	15000.00
793	390	1	2025-08-16	3	2500.00
794	390	5	2025-08-16	1	15000.00
795	390	5	2025-08-16	1	15000.00
796	391	1	2025-08-20	2	2500.00
797	391	5	2025-08-20	3	15000.00
798	391	5	2025-08-21	2	15000.00
799	392	7	2025-08-25	2	12000.00
800	393	2	2025-08-31	2	6000.00
801	393	1	2025-09-01	2	2500.00
802	393	1	2025-09-01	3	2500.00
803	393	2	2025-09-01	2	6000.00
804	394	1	2025-09-05	3	2500.00
805	394	7	2025-09-06	4	12000.00
806	394	1	2025-09-06	4	2500.00
807	395	3	2025-09-11	3	3500.00
808	395	3	2025-09-10	4	3500.00
809	395	7	2025-09-11	2	12000.00
810	395	7	2025-09-11	2	12000.00
811	397	5	2025-09-16	2	15000.00
812	398	1	2025-09-20	3	2500.00
813	398	6	2025-09-19	3	600.00
814	398	3	2025-09-20	3	3500.00
815	399	3	2025-09-23	3	3500.00
816	399	2	2025-09-22	2	6000.00
817	399	3	2025-09-26	4	3500.00
818	401	5	2025-07-02	2	15000.00
819	401	4	2025-07-01	3	1800.00
820	401	1	2025-07-02	2	2500.00
821	402	6	2025-07-05	2	600.00
822	402	1	2025-07-05	1	2500.00
823	402	7	2025-07-06	3	12000.00
824	402	7	2025-07-06	2	12000.00
825	403	3	2025-07-09	1	3500.00
826	403	1	2025-07-09	1	2500.00
827	404	1	2025-07-11	2	2500.00
828	405	2	2025-07-16	4	6000.00
829	405	1	2025-07-15	4	2500.00
830	405	7	2025-07-16	1	12000.00
831	406	2	2025-07-21	1	6000.00
832	406	5	2025-07-21	4	15000.00
833	408	2	2025-07-31	1	6000.00
834	408	4	2025-07-31	3	1800.00
835	408	7	2025-07-30	4	12000.00
836	408	4	2025-07-31	3	1800.00
837	409	3	2025-08-04	3	3500.00
838	409	1	2025-08-04	2	2500.00
839	410	4	2025-08-07	1	1800.00
840	410	2	2025-08-07	4	6000.00
841	410	7	2025-08-07	2	12000.00
842	411	3	2025-08-14	1	3500.00
843	411	4	2025-08-13	2	1800.00
844	412	6	2025-08-18	2	600.00
845	412	2	2025-08-17	2	6000.00
846	412	6	2025-08-16	1	600.00
847	412	7	2025-08-18	3	12000.00
848	413	6	2025-08-21	1	600.00
849	414	7	2025-08-24	1	12000.00
850	415	7	2025-08-31	1	12000.00
851	415	6	2025-08-30	4	600.00
852	416	6	2025-09-05	2	600.00
853	416	3	2025-09-05	2	3500.00
854	417	1	2025-09-08	4	2500.00
855	417	7	2025-09-07	4	12000.00
856	418	7	2025-09-10	3	12000.00
857	419	4	2025-09-15	2	1800.00
858	419	7	2025-09-15	1	12000.00
859	420	3	2025-09-19	3	3500.00
860	421	6	2025-09-23	3	600.00
861	421	1	2025-09-24	3	2500.00
862	421	1	2025-09-22	2	2500.00
863	421	1	2025-09-21	3	2500.00
864	422	4	2025-09-28	2	1800.00
865	422	2	2025-09-27	2	6000.00
866	424	4	2025-07-02	2	1800.00
867	424	5	2025-07-02	3	15000.00
868	424	2	2025-07-02	3	6000.00
869	425	4	2025-07-03	3	1800.00
870	425	4	2025-07-03	3	1800.00
871	426	4	2025-07-08	3	1800.00
872	426	3	2025-07-07	1	3500.00
873	429	7	2025-07-21	2	12000.00
874	429	4	2025-07-21	3	1800.00
875	429	2	2025-07-21	3	6000.00
876	430	5	2025-07-25	2	15000.00
877	431	3	2025-07-27	2	3500.00
878	432	7	2025-07-31	4	12000.00
879	433	2	2025-08-01	3	6000.00
880	434	7	2025-08-08	1	12000.00
881	434	3	2025-08-08	2	3500.00
882	434	7	2025-08-07	3	12000.00
883	435	1	2025-08-09	3	2500.00
884	435	5	2025-08-09	2	15000.00
885	435	2	2025-08-10	4	6000.00
886	435	7	2025-08-11	3	12000.00
887	436	1	2025-08-12	4	2500.00
888	438	3	2025-08-19	3	3500.00
889	438	2	2025-08-19	2	6000.00
890	438	1	2025-08-19	4	2500.00
891	438	3	2025-08-19	3	3500.00
892	439	5	2025-08-21	2	15000.00
893	439	2	2025-08-21	3	6000.00
894	440	2	2025-08-25	4	6000.00
895	441	4	2025-08-27	1	1800.00
896	441	3	2025-08-28	4	3500.00
897	441	1	2025-08-28	3	2500.00
898	445	2	2025-09-12	3	6000.00
899	445	6	2025-09-12	3	600.00
900	445	5	2025-09-14	4	15000.00
901	446	7	2025-09-19	3	12000.00
902	447	1	2025-09-21	1	2500.00
903	447	3	2025-09-21	3	3500.00
904	448	7	2025-09-24	2	12000.00
905	450	4	2025-07-01	2	1800.00
906	450	4	2025-07-01	2	1800.00
907	450	5	2025-07-01	3	15000.00
908	451	1	2025-07-04	4	2500.00
909	451	1	2025-07-06	1	2500.00
910	452	4	2025-07-08	2	1800.00
911	452	6	2025-07-07	3	600.00
912	452	1	2025-07-09	1	2500.00
913	452	6	2025-07-10	3	600.00
914	453	4	2025-07-13	3	1800.00
915	453	6	2025-07-12	3	600.00
916	453	4	2025-07-12	4	1800.00
917	454	5	2025-07-15	2	15000.00
918	454	5	2025-07-14	3	15000.00
919	454	5	2025-07-14	1	15000.00
920	455	3	2025-07-22	1	3500.00
921	455	2	2025-07-21	2	6000.00
922	456	4	2025-07-25	2	1800.00
923	458	4	2025-08-06	3	1800.00
924	458	1	2025-08-06	2	2500.00
925	458	1	2025-08-06	2	2500.00
926	458	5	2025-08-06	3	15000.00
927	459	2	2025-08-10	3	6000.00
928	459	3	2025-08-09	2	3500.00
929	460	3	2025-08-14	3	3500.00
930	463	7	2025-08-26	2	12000.00
931	463	3	2025-08-27	3	3500.00
932	463	3	2025-08-27	2	3500.00
933	464	7	2025-08-31	3	12000.00
934	464	7	2025-08-31	2	12000.00
935	464	1	2025-09-01	2	2500.00
936	465	4	2025-09-03	3	1800.00
937	465	7	2025-09-02	4	12000.00
938	466	7	2025-09-06	1	12000.00
939	466	6	2025-09-09	1	600.00
940	467	6	2025-09-12	1	600.00
941	467	6	2025-09-13	1	600.00
942	467	6	2025-09-12	2	600.00
943	467	7	2025-09-12	2	12000.00
944	468	4	2025-09-16	2	1800.00
945	469	3	2025-09-19	3	3500.00
946	469	7	2025-09-19	4	12000.00
947	469	2	2025-09-19	3	6000.00
948	470	2	2025-09-25	1	6000.00
949	472	2	2025-09-30	1	6000.00
950	472	6	2025-09-30	1	600.00
951	472	1	2025-09-30	3	2500.00
952	473	6	2025-07-01	3	600.00
953	474	1	2025-07-06	1	2500.00
954	474	2	2025-07-06	3	6000.00
955	475	1	2025-07-12	4	2500.00
956	475	4	2025-07-11	3	1800.00
957	475	4	2025-07-12	2	1800.00
958	475	4	2025-07-11	2	1800.00
959	477	6	2025-07-18	1	600.00
960	478	2	2025-07-19	2	6000.00
961	478	1	2025-07-21	2	2500.00
962	479	3	2025-07-25	3	3500.00
963	479	6	2025-07-26	3	600.00
964	480	6	2025-07-28	2	600.00
965	482	1	2025-08-06	3	2500.00
966	482	7	2025-08-05	3	12000.00
967	483	5	2025-08-14	2	15000.00
968	484	3	2025-08-19	1	3500.00
969	484	4	2025-08-19	4	1800.00
970	485	7	2025-08-26	4	12000.00
971	485	2	2025-08-27	2	6000.00
972	485	3	2025-08-27	4	3500.00
973	486	3	2025-08-29	1	3500.00
974	486	3	2025-08-30	2	3500.00
975	486	6	2025-08-30	1	600.00
976	488	7	2025-09-11	1	12000.00
977	488	5	2025-09-09	2	15000.00
978	488	1	2025-09-09	2	2500.00
979	489	1	2025-09-14	2	2500.00
980	489	4	2025-09-15	3	1800.00
981	489	2	2025-09-15	1	6000.00
982	490	1	2025-09-18	3	2500.00
983	490	4	2025-09-17	1	1800.00
984	490	1	2025-09-18	3	2500.00
985	491	6	2025-09-22	3	600.00
986	491	6	2025-09-22	2	600.00
987	492	3	2025-09-23	2	3500.00
988	492	4	2025-09-23	3	1800.00
989	493	7	2025-09-30	2	12000.00
990	493	2	2025-09-30	3	6000.00
991	494	2	2025-07-02	1	6000.00
992	494	5	2025-07-01	3	15000.00
993	494	3	2025-07-02	2	3500.00
994	495	3	2025-07-04	1	3500.00
995	495	2	2025-07-07	2	6000.00
996	495	1	2025-07-05	2	2500.00
997	496	1	2025-07-13	2	2500.00
998	496	4	2025-07-13	2	1800.00
999	497	1	2025-07-15	4	2500.00
1000	498	5	2025-07-22	3	15000.00
1001	498	3	2025-07-21	1	3500.00
1002	499	2	2025-07-24	1	6000.00
1003	499	5	2025-07-24	1	15000.00
1004	499	5	2025-07-24	3	15000.00
1005	500	7	2025-07-27	2	12000.00
1006	500	6	2025-07-27	2	600.00
1007	500	7	2025-07-27	4	12000.00
1008	500	2	2025-07-27	4	6000.00
1009	501	4	2025-07-30	1	1800.00
1010	501	7	2025-07-31	3	12000.00
1011	502	1	2025-08-05	4	2500.00
1012	503	7	2025-08-09	1	12000.00
1013	505	3	2025-08-16	3	3500.00
1014	505	1	2025-08-16	2	2500.00
1015	505	6	2025-08-17	3	600.00
1016	506	1	2025-08-22	2	2500.00
1017	507	3	2025-08-25	2	3500.00
1018	507	6	2025-08-26	2	600.00
1019	507	4	2025-08-25	2	1800.00
1020	507	4	2025-08-27	2	1800.00
1021	508	7	2025-08-31	2	12000.00
1022	508	6	2025-08-30	3	600.00
1023	508	4	2025-08-31	4	1800.00
1024	509	4	2025-09-01	4	1800.00
1025	509	2	2025-09-03	2	6000.00
1026	509	1	2025-09-02	3	2500.00
1027	511	6	2025-09-10	2	600.00
1028	511	2	2025-09-08	1	6000.00
1029	511	3	2025-09-09	1	3500.00
1030	512	3	2025-09-13	2	3500.00
1031	512	1	2025-09-13	3	2500.00
1032	512	1	2025-09-12	2	2500.00
1033	513	1	2025-09-16	3	2500.00
1034	514	3	2025-09-19	3	3500.00
1035	514	7	2025-09-20	2	12000.00
1036	515	2	2025-09-24	3	6000.00
1037	516	5	2025-09-27	2	15000.00
1038	517	7	2025-09-30	2	12000.00
1039	519	6	2025-07-03	3	600.00
1040	519	1	2025-07-03	4	2500.00
1041	520	6	2025-07-07	2	600.00
1042	520	5	2025-07-06	3	15000.00
1043	520	3	2025-07-07	3	3500.00
1044	521	2	2025-07-10	2	6000.00
1045	521	3	2025-07-11	2	3500.00
1046	522	6	2025-07-16	2	600.00
1047	522	1	2025-07-16	2	2500.00
1048	523	3	2025-07-18	1	3500.00
1049	523	2	2025-07-19	3	6000.00
1050	523	6	2025-07-20	3	600.00
1051	523	3	2025-07-18	3	3500.00
1052	524	2	2025-07-22	1	6000.00
1053	524	3	2025-07-23	1	3500.00
1054	524	5	2025-07-22	3	15000.00
1055	525	3	2025-07-24	3	3500.00
1056	525	5	2025-07-25	2	15000.00
1057	525	4	2025-07-25	2	1800.00
1058	526	5	2025-07-28	2	15000.00
1059	526	3	2025-07-27	4	3500.00
1060	526	3	2025-07-30	1	3500.00
1061	527	2	2025-08-05	1	6000.00
1062	528	7	2025-08-09	1	12000.00
1063	529	5	2025-08-12	4	15000.00
1064	529	1	2025-08-12	2	2500.00
1065	529	5	2025-08-12	1	15000.00
1066	530	3	2025-08-16	1	3500.00
1067	531	2	2025-08-19	2	6000.00
1068	531	1	2025-08-19	3	2500.00
1069	532	2	2025-08-23	4	6000.00
1070	532	2	2025-08-22	2	6000.00
1071	534	2	2025-09-03	2	6000.00
1072	534	6	2025-09-02	2	600.00
1073	534	3	2025-09-02	3	3500.00
1074	534	1	2025-09-04	4	2500.00
1075	535	3	2025-09-07	2	3500.00
1076	535	5	2025-09-07	3	15000.00
1077	535	4	2025-09-06	3	1800.00
1078	536	5	2025-09-09	2	15000.00
1079	537	7	2025-09-12	1	12000.00
1080	537	2	2025-09-14	2	6000.00
1081	537	5	2025-09-11	1	15000.00
1082	538	5	2025-09-16	2	15000.00
1083	538	4	2025-09-16	2	1800.00
1084	539	7	2025-09-20	1	12000.00
1085	539	1	2025-09-19	2	2500.00
1086	540	6	2025-09-25	3	600.00
1087	540	6	2025-09-24	2	600.00
1088	540	4	2025-09-24	2	1800.00
1089	540	4	2025-09-25	3	1800.00
1090	541	5	2025-09-28	4	15000.00
1091	542	5	2025-09-30	1	15000.00
1092	542	1	2025-10-02	4	2500.00
1093	542	6	2025-09-30	2	600.00
1094	542	4	2025-10-02	3	1800.00
1095	543	4	2025-07-02	2	1800.00
1096	544	6	2025-07-05	3	600.00
1097	544	7	2025-07-05	2	12000.00
1098	544	1	2025-07-05	3	2500.00
1099	545	1	2025-07-06	3	2500.00
1100	545	6	2025-07-06	3	600.00
1101	546	6	2025-07-09	3	600.00
1102	546	7	2025-07-10	4	12000.00
1103	546	7	2025-07-08	2	12000.00
1104	547	3	2025-07-13	2	3500.00
1105	547	3	2025-07-14	4	3500.00
1106	547	1	2025-07-14	1	2500.00
1107	547	6	2025-07-13	3	600.00
1108	548	1	2025-07-17	4	2500.00
1109	549	5	2025-07-19	2	15000.00
1110	549	3	2025-07-19	4	3500.00
1111	549	4	2025-07-19	3	1800.00
1112	550	4	2025-07-22	2	1800.00
1113	550	4	2025-07-22	2	1800.00
1114	551	4	2025-07-25	2	1800.00
1115	552	4	2025-07-28	2	1800.00
1116	553	6	2025-08-03	3	600.00
1117	553	3	2025-08-03	1	3500.00
1118	554	6	2025-08-07	1	600.00
1119	554	3	2025-08-07	4	3500.00
1120	554	7	2025-08-07	1	12000.00
1121	555	3	2025-08-10	3	3500.00
1122	556	6	2025-08-14	4	600.00
1123	556	3	2025-08-16	3	3500.00
1124	557	3	2025-08-19	1	3500.00
1125	558	6	2025-08-25	1	600.00
1126	558	7	2025-08-25	2	12000.00
1127	558	2	2025-08-25	4	6000.00
1128	558	6	2025-08-25	4	600.00
1129	560	6	2025-08-30	3	600.00
1130	560	6	2025-08-30	1	600.00
1131	560	2	2025-08-30	2	6000.00
1132	560	5	2025-08-30	4	15000.00
1133	561	3	2025-09-02	3	3500.00
1134	562	7	2025-09-08	3	12000.00
1135	562	3	2025-09-07	2	3500.00
1136	564	5	2025-09-15	4	15000.00
1137	564	1	2025-09-15	1	2500.00
1138	565	6	2025-09-23	1	600.00
1139	565	2	2025-09-22	1	6000.00
1140	566	7	2025-09-24	2	12000.00
1141	566	1	2025-09-24	3	2500.00
1142	567	3	2025-09-29	2	3500.00
1143	567	7	2025-09-28	2	12000.00
1144	567	3	2025-09-28	3	3500.00
1145	567	1	2025-09-29	4	2500.00
1146	568	4	2025-07-05	1	1800.00
1147	568	3	2025-07-02	3	3500.00
1148	568	4	2025-07-03	3	1800.00
1149	569	2	2025-07-07	4	6000.00
1150	569	1	2025-07-08	3	2500.00
1151	569	4	2025-07-07	1	1800.00
1152	569	5	2025-07-07	3	15000.00
1153	570	1	2025-07-12	2	2500.00
1154	570	1	2025-07-11	3	2500.00
1155	570	3	2025-07-11	3	3500.00
1156	571	1	2025-07-15	3	2500.00
1157	571	4	2025-07-16	2	1800.00
1158	572	6	2025-07-19	2	600.00
1159	572	3	2025-07-19	2	3500.00
1160	572	2	2025-07-19	4	6000.00
1161	573	1	2025-07-22	4	2500.00
1162	573	5	2025-07-22	3	15000.00
1163	574	6	2025-07-25	4	600.00
1164	575	5	2025-07-31	2	15000.00
1165	575	6	2025-08-01	2	600.00
1166	576	7	2025-08-04	3	12000.00
1167	577	7	2025-08-08	4	12000.00
1168	578	2	2025-08-11	1	6000.00
1169	579	5	2025-08-15	4	15000.00
1170	580	5	2025-08-20	3	15000.00
1171	580	6	2025-08-20	2	600.00
1172	581	1	2025-08-27	3	2500.00
1173	581	7	2025-08-28	3	12000.00
1174	582	6	2025-08-31	3	600.00
1175	582	5	2025-08-30	3	15000.00
1176	582	5	2025-08-30	1	15000.00
1177	583	7	2025-09-02	3	12000.00
1178	583	3	2025-09-03	2	3500.00
1179	584	1	2025-09-06	2	2500.00
1180	584	1	2025-09-06	4	2500.00
1181	584	3	2025-09-07	2	3500.00
1182	584	1	2025-09-05	2	2500.00
1183	587	2	2025-09-17	1	6000.00
1184	587	1	2025-09-18	1	2500.00
1185	588	7	2025-09-21	3	12000.00
1186	588	2	2025-09-21	3	6000.00
1187	588	6	2025-09-21	3	600.00
1188	589	2	2025-09-22	1	6000.00
1189	589	7	2025-09-22	3	12000.00
1190	589	2	2025-09-23	4	6000.00
1191	590	2	2025-09-26	2	6000.00
1192	590	6	2025-09-27	1	600.00
1193	591	1	2025-10-01	2	2500.00
1194	592	7	2025-07-02	4	12000.00
1195	592	2	2025-07-02	3	6000.00
1196	592	6	2025-07-01	2	600.00
1197	592	1	2025-07-02	2	2500.00
1198	593	4	2025-07-08	2	1800.00
1199	593	5	2025-07-08	2	15000.00
1200	594	5	2025-07-13	4	15000.00
1201	595	7	2025-07-18	2	12000.00
1202	595	6	2025-07-17	4	600.00
1203	595	5	2025-07-19	4	15000.00
1204	596	7	2025-07-24	2	12000.00
1205	597	6	2025-07-29	4	600.00
1206	597	3	2025-07-29	3	3500.00
1207	598	6	2025-08-02	3	600.00
1208	598	5	2025-08-02	4	15000.00
1209	598	1	2025-08-03	1	2500.00
1210	599	5	2025-08-07	1	15000.00
1211	599	2	2025-08-07	1	6000.00
1212	600	6	2025-08-12	4	600.00
1213	600	3	2025-08-10	3	3500.00
1214	601	7	2025-08-15	3	12000.00
1215	601	3	2025-08-16	3	3500.00
1216	601	2	2025-08-17	3	6000.00
1217	602	4	2025-08-20	2	1800.00
1218	602	3	2025-08-20	2	3500.00
1219	602	5	2025-08-22	2	15000.00
1220	603	5	2025-08-26	2	15000.00
1221	603	5	2025-08-26	2	15000.00
1222	604	5	2025-08-31	2	15000.00
1223	605	3	2025-09-03	3	3500.00
1224	606	5	2025-09-05	2	15000.00
1225	607	1	2025-09-10	4	2500.00
1226	607	7	2025-09-10	3	12000.00
1227	608	3	2025-09-14	4	3500.00
1228	610	1	2025-09-20	1	2500.00
1229	610	5	2025-09-20	3	15000.00
1230	610	3	2025-09-20	1	3500.00
1231	610	6	2025-09-20	1	600.00
1232	611	5	2025-09-23	4	15000.00
1233	611	7	2025-09-23	3	12000.00
1234	611	5	2025-09-23	3	15000.00
1235	612	5	2025-09-28	3	15000.00
1236	613	5	2025-09-30	3	15000.00
1237	614	4	2025-07-02	2	1800.00
1238	614	4	2025-07-04	1	1800.00
1239	615	7	2025-07-09	1	12000.00
1240	615	1	2025-07-08	3	2500.00
1241	615	5	2025-07-09	4	15000.00
1242	616	4	2025-07-15	2	1800.00
1243	616	2	2025-07-15	4	6000.00
1244	617	4	2025-07-19	3	1800.00
1245	617	1	2025-07-18	2	2500.00
1246	617	7	2025-07-18	4	12000.00
1247	618	6	2025-07-21	2	600.00
1248	619	3	2025-07-24	2	3500.00
1249	619	6	2025-07-24	2	600.00
1250	619	1	2025-07-25	4	2500.00
1251	621	5	2025-07-30	2	15000.00
1252	621	5	2025-07-30	4	15000.00
1253	621	1	2025-08-01	2	2500.00
1254	622	1	2025-08-03	2	2500.00
1255	623	5	2025-08-12	3	15000.00
1256	623	3	2025-08-11	2	3500.00
1257	623	7	2025-08-09	3	12000.00
1258	624	1	2025-08-16	2	2500.00
1259	624	4	2025-08-15	1	1800.00
1260	625	3	2025-08-19	1	3500.00
1261	626	4	2025-08-21	2	1800.00
1262	627	2	2025-08-22	1	6000.00
1263	628	1	2025-08-26	2	2500.00
1264	628	6	2025-08-27	2	600.00
1265	629	2	2025-08-30	1	6000.00
1266	630	5	2025-09-07	2	15000.00
1267	630	3	2025-09-04	3	3500.00
1268	632	7	2025-09-12	1	12000.00
1269	632	2	2025-09-12	3	6000.00
1270	632	7	2025-09-12	4	12000.00
1271	633	2	2025-09-17	2	6000.00
1272	633	1	2025-09-16	3	2500.00
1273	634	2	2025-09-21	3	6000.00
1274	635	6	2025-09-25	3	600.00
1275	635	3	2025-09-27	2	3500.00
1276	635	6	2025-09-28	4	600.00
1277	636	6	2025-09-30	2	600.00
1278	636	7	2025-10-04	1	12000.00
1279	636	5	2025-10-02	3	15000.00
1280	637	5	2025-07-02	3	15000.00
1281	637	3	2025-07-01	3	3500.00
1282	637	5	2025-07-02	4	15000.00
1283	638	7	2025-07-05	4	12000.00
1284	638	4	2025-07-04	4	1800.00
1285	638	3	2025-07-05	1	3500.00
1286	639	2	2025-07-10	3	6000.00
1287	639	3	2025-07-10	2	3500.00
1288	641	2	2025-07-18	4	6000.00
1289	641	1	2025-07-18	4	2500.00
1290	641	3	2025-07-20	2	3500.00
1291	641	5	2025-07-19	2	15000.00
1292	642	1	2025-07-23	3	2500.00
1293	642	5	2025-07-25	4	15000.00
1294	642	7	2025-07-24	4	12000.00
1295	643	1	2025-07-29	4	2500.00
1296	643	7	2025-07-28	3	12000.00
1297	643	4	2025-07-28	2	1800.00
1298	645	1	2025-08-04	2	2500.00
1299	646	1	2025-08-06	1	2500.00
1300	646	5	2025-08-06	1	15000.00
1301	647	4	2025-08-08	1	1800.00
1302	647	3	2025-08-08	1	3500.00
1303	647	5	2025-08-08	3	15000.00
1304	648	1	2025-08-11	2	2500.00
1305	648	5	2025-08-11	2	15000.00
1306	648	3	2025-08-11	2	3500.00
1307	648	7	2025-08-11	1	12000.00
1308	649	5	2025-08-13	2	15000.00
1309	649	4	2025-08-15	3	1800.00
1310	650	6	2025-08-19	2	600.00
1311	650	2	2025-08-19	1	6000.00
1312	651	4	2025-08-20	2	1800.00
1313	651	4	2025-08-20	3	1800.00
1314	651	6	2025-08-20	3	600.00
1315	652	6	2025-08-23	1	600.00
1316	652	2	2025-08-23	3	6000.00
1317	653	3	2025-08-27	3	3500.00
1318	654	1	2025-08-31	3	2500.00
1319	654	5	2025-08-31	1	15000.00
1320	655	2	2025-09-04	1	6000.00
1321	655	6	2025-09-03	3	600.00
1322	655	3	2025-09-04	2	3500.00
1323	655	3	2025-09-04	2	3500.00
1324	656	4	2025-09-06	1	1800.00
1325	656	5	2025-09-07	2	15000.00
1326	656	1	2025-09-06	4	2500.00
1327	656	4	2025-09-07	3	1800.00
1328	657	3	2025-09-11	1	3500.00
1329	658	4	2025-09-15	1	1800.00
1330	658	2	2025-09-14	4	6000.00
1331	660	3	2025-09-26	2	3500.00
1332	660	3	2025-09-27	3	3500.00
1333	660	2	2025-09-25	2	6000.00
1334	661	6	2025-10-04	4	600.00
1335	661	7	2025-09-30	2	12000.00
1336	662	6	2025-07-01	3	600.00
1337	662	1	2025-07-02	2	2500.00
1338	662	5	2025-07-02	4	15000.00
1339	663	3	2025-07-04	2	3500.00
1340	663	3	2025-07-04	2	3500.00
1341	663	2	2025-07-03	3	6000.00
1342	663	6	2025-07-04	2	600.00
1343	664	2	2025-07-07	3	6000.00
1344	664	6	2025-07-07	3	600.00
1345	664	7	2025-07-07	4	12000.00
1346	665	2	2025-07-12	3	6000.00
1347	665	4	2025-07-11	3	1800.00
1348	666	6	2025-07-17	4	600.00
1349	666	6	2025-07-17	3	600.00
1350	666	6	2025-07-17	1	600.00
1351	667	4	2025-07-22	3	1800.00
1352	667	4	2025-07-22	4	1800.00
1353	668	6	2025-07-25	3	600.00
1354	669	4	2025-07-27	1	1800.00
1355	670	2	2025-07-29	4	6000.00
1356	670	2	2025-07-29	1	6000.00
1357	671	3	2025-08-01	2	3500.00
1358	671	1	2025-08-02	4	2500.00
1359	672	3	2025-08-04	1	3500.00
1360	672	1	2025-08-04	1	2500.00
1361	672	5	2025-08-04	1	15000.00
1362	672	4	2025-08-04	3	1800.00
1363	673	5	2025-08-07	2	15000.00
1364	673	1	2025-08-08	2	2500.00
1365	674	5	2025-08-14	3	15000.00
1366	674	5	2025-08-14	3	15000.00
1367	674	7	2025-08-14	4	12000.00
1368	675	1	2025-08-19	3	2500.00
1369	675	6	2025-08-18	4	600.00
1370	675	4	2025-08-20	1	1800.00
1371	675	6	2025-08-18	3	600.00
1372	676	3	2025-08-21	2	3500.00
1373	676	1	2025-08-21	2	2500.00
1374	677	2	2025-08-29	4	6000.00
1375	677	5	2025-08-28	2	15000.00
1376	677	1	2025-08-26	2	2500.00
1377	678	2	2025-08-31	4	6000.00
1378	678	2	2025-08-31	4	6000.00
1379	679	6	2025-09-04	1	600.00
1380	679	3	2025-09-04	3	3500.00
1381	680	3	2025-09-08	4	3500.00
1382	681	3	2025-09-12	2	3500.00
1383	681	2	2025-09-12	3	6000.00
1384	681	6	2025-09-12	1	600.00
1385	681	5	2025-09-12	3	15000.00
1386	682	6	2025-09-19	4	600.00
1387	684	6	2025-09-26	2	600.00
1388	685	5	2025-09-30	2	15000.00
1389	685	3	2025-09-28	3	3500.00
1390	686	5	2025-07-02	2	15000.00
1391	687	2	2025-07-03	3	6000.00
1392	687	3	2025-07-03	2	3500.00
1393	687	3	2025-07-03	2	3500.00
1394	687	4	2025-07-03	2	1800.00
1395	688	2	2025-07-07	4	6000.00
1396	688	5	2025-07-06	2	15000.00
1397	689	7	2025-07-11	3	12000.00
1398	689	4	2025-07-13	2	1800.00
1399	690	2	2025-07-15	4	6000.00
1400	690	5	2025-07-15	3	15000.00
1401	691	4	2025-07-18	2	1800.00
1402	692	1	2025-07-23	2	2500.00
1403	693	5	2025-07-28	1	15000.00
1404	693	4	2025-07-28	4	1800.00
1405	695	7	2025-08-05	1	12000.00
1406	695	1	2025-08-07	2	2500.00
1407	695	3	2025-08-07	2	3500.00
1408	695	7	2025-08-06	3	12000.00
1409	697	7	2025-08-15	3	12000.00
1410	698	3	2025-08-19	3	3500.00
1411	698	6	2025-08-19	1	600.00
1412	699	2	2025-08-22	3	6000.00
1413	699	7	2025-08-23	3	12000.00
1414	700	6	2025-08-25	3	600.00
1415	700	5	2025-08-27	2	15000.00
1416	703	2	2025-09-09	3	6000.00
1417	704	4	2025-09-15	3	1800.00
1418	705	2	2025-09-18	2	6000.00
1419	706	5	2025-09-23	4	15000.00
1420	707	2	2025-09-28	4	6000.00
1421	708	3	2025-07-02	2	3500.00
1422	709	6	2025-07-05	2	600.00
1423	709	3	2025-07-05	1	3500.00
1424	709	1	2025-07-04	3	2500.00
1425	710	5	2025-07-10	2	15000.00
1426	711	4	2025-07-16	1	1800.00
1427	713	1	2025-07-29	2	2500.00
1428	713	3	2025-07-30	4	3500.00
1429	713	4	2025-07-30	3	1800.00
1430	714	3	2025-08-02	4	3500.00
1431	714	4	2025-08-02	4	1800.00
1432	714	6	2025-08-02	3	600.00
1433	714	3	2025-08-02	2	3500.00
1434	715	4	2025-08-07	3	1800.00
1435	715	6	2025-08-05	2	600.00
1436	715	3	2025-08-06	3	3500.00
1437	717	3	2025-08-12	2	3500.00
1438	718	5	2025-08-17	4	15000.00
1439	719	5	2025-08-24	2	15000.00
1440	721	6	2025-09-01	2	600.00
1441	721	6	2025-09-01	3	600.00
1442	721	1	2025-09-02	4	2500.00
1443	722	4	2025-09-05	4	1800.00
1444	722	2	2025-09-06	2	6000.00
1445	722	4	2025-09-07	3	1800.00
1446	722	4	2025-09-07	2	1800.00
1447	723	7	2025-09-11	3	12000.00
1448	724	1	2025-09-16	3	2500.00
1449	725	5	2025-09-22	2	15000.00
1450	725	4	2025-09-21	3	1800.00
1451	725	4	2025-09-21	2	1800.00
1452	726	3	2025-09-26	1	3500.00
1453	727	5	2025-07-02	3	15000.00
1454	727	5	2025-07-01	2	15000.00
1455	728	2	2025-07-04	3	6000.00
1456	728	3	2025-07-04	3	3500.00
1457	730	3	2025-07-13	1	3500.00
1458	730	2	2025-07-13	4	6000.00
1459	730	7	2025-07-13	2	12000.00
1460	731	3	2025-07-16	3	3500.00
1461	731	5	2025-07-14	2	15000.00
1462	731	1	2025-07-15	2	2500.00
1463	731	1	2025-07-14	3	2500.00
1464	732	1	2025-07-19	1	2500.00
1465	732	4	2025-07-19	3	1800.00
1466	733	2	2025-07-21	3	6000.00
1467	733	4	2025-07-22	3	1800.00
1468	733	1	2025-07-22	1	2500.00
1469	734	4	2025-07-26	3	1800.00
1470	735	4	2025-07-30	3	1800.00
1471	737	1	2025-08-07	1	2500.00
1472	737	7	2025-08-07	4	12000.00
1473	737	2	2025-08-07	1	6000.00
1474	738	6	2025-08-09	3	600.00
1475	738	4	2025-08-09	1	1800.00
1476	738	6	2025-08-09	2	600.00
1477	739	6	2025-08-13	2	600.00
1478	739	1	2025-08-11	2	2500.00
1479	739	2	2025-08-12	2	6000.00
1480	740	6	2025-08-15	4	600.00
1481	740	2	2025-08-19	4	6000.00
1482	740	4	2025-08-18	4	1800.00
1483	741	4	2025-08-22	3	1800.00
1484	741	5	2025-08-22	1	15000.00
1485	742	7	2025-08-25	1	12000.00
1486	742	5	2025-08-25	2	15000.00
1487	742	2	2025-08-24	4	6000.00
1488	743	4	2025-08-28	3	1800.00
1489	743	2	2025-08-28	3	6000.00
1490	744	4	2025-09-01	2	1800.00
1491	744	3	2025-09-02	3	3500.00
1492	745	7	2025-09-06	2	12000.00
1493	745	5	2025-09-05	3	15000.00
1494	746	1	2025-09-07	3	2500.00
1495	746	6	2025-09-07	3	600.00
1496	746	6	2025-09-08	3	600.00
1497	747	5	2025-09-13	1	15000.00
1498	747	4	2025-09-13	1	1800.00
1499	747	7	2025-09-13	4	12000.00
1500	748	1	2025-09-17	4	2500.00
1501	748	2	2025-09-17	2	6000.00
1502	748	4	2025-09-18	4	1800.00
1503	749	7	2025-09-22	4	12000.00
1504	750	2	2025-09-29	3	6000.00
1505	750	3	2025-09-26	3	3500.00
1506	750	4	2025-09-25	3	1800.00
1507	751	6	2025-09-30	2	600.00
1508	752	1	2025-07-02	1	2500.00
1509	752	3	2025-07-03	2	3500.00
1510	752	1	2025-07-03	4	2500.00
1511	753	6	2025-07-06	3	600.00
1512	755	6	2025-07-18	4	600.00
1513	755	3	2025-07-19	4	3500.00
1514	755	4	2025-07-21	4	1800.00
1515	756	4	2025-07-27	3	1800.00
1516	756	6	2025-07-27	1	600.00
1517	756	7	2025-07-27	2	12000.00
1518	757	3	2025-07-31	3	3500.00
1519	757	6	2025-07-31	1	600.00
1520	757	7	2025-08-01	3	12000.00
1521	759	2	2025-08-10	4	6000.00
1522	759	2	2025-08-08	1	6000.00
1523	759	5	2025-08-12	1	15000.00
1524	760	3	2025-08-15	2	3500.00
1525	761	6	2025-08-20	1	600.00
1526	761	7	2025-08-20	2	12000.00
1527	761	6	2025-08-21	4	600.00
1528	761	6	2025-08-21	4	600.00
1529	762	7	2025-08-25	2	12000.00
1530	762	7	2025-08-27	3	12000.00
1531	762	2	2025-08-25	2	6000.00
1532	763	6	2025-08-30	2	600.00
1533	763	6	2025-08-30	3	600.00
1534	764	6	2025-09-03	2	600.00
1535	764	5	2025-09-02	2	15000.00
1536	765	4	2025-09-05	1	1800.00
1537	765	7	2025-09-05	3	12000.00
1538	766	6	2025-09-07	2	600.00
1539	767	1	2025-09-10	2	2500.00
1540	768	1	2025-09-15	3	2500.00
1541	768	7	2025-09-15	1	12000.00
1542	768	6	2025-09-15	4	600.00
1543	769	6	2025-09-18	1	600.00
1544	769	1	2025-09-17	2	2500.00
1545	769	7	2025-09-18	3	12000.00
1546	769	2	2025-09-18	4	6000.00
1547	770	4	2025-09-24	3	1800.00
1548	770	6	2025-09-25	3	600.00
1549	771	4	2025-09-28	4	1800.00
1550	771	6	2025-09-28	3	600.00
1551	771	1	2025-09-27	1	2500.00
1552	776	4	2025-07-09	3	1800.00
1553	776	7	2025-07-10	4	12000.00
1554	776	2	2025-07-10	2	6000.00
1555	777	3	2025-07-12	4	3500.00
1556	778	7	2025-07-13	1	12000.00
1557	779	1	2025-07-15	1	2500.00
1558	780	5	2025-07-17	4	15000.00
1559	780	3	2025-07-17	2	3500.00
1560	780	7	2025-07-16	2	12000.00
1561	781	6	2025-07-21	1	600.00
1562	781	5	2025-07-20	3	15000.00
1563	781	4	2025-07-20	1	1800.00
1564	782	1	2025-07-23	3	2500.00
1565	782	2	2025-07-24	1	6000.00
1566	783	5	2025-07-27	1	15000.00
1567	783	4	2025-07-29	2	1800.00
1568	784	6	2025-08-02	4	600.00
1569	784	6	2025-08-02	3	600.00
1570	785	6	2025-08-04	1	600.00
1571	785	5	2025-08-04	2	15000.00
1572	785	7	2025-08-04	2	12000.00
1573	785	7	2025-08-04	2	12000.00
1574	786	2	2025-08-07	4	6000.00
1575	786	7	2025-08-07	2	12000.00
1576	786	4	2025-08-08	2	1800.00
1577	786	2	2025-08-07	2	6000.00
1578	788	7	2025-08-12	4	12000.00
1579	788	4	2025-08-13	4	1800.00
1580	788	1	2025-08-12	4	2500.00
1581	788	7	2025-08-12	2	12000.00
1582	789	4	2025-08-16	3	1800.00
1583	789	1	2025-08-15	3	2500.00
1584	789	6	2025-08-16	4	600.00
1585	790	1	2025-08-18	2	2500.00
1586	790	7	2025-08-18	3	12000.00
1587	790	7	2025-08-17	2	12000.00
1588	791	6	2025-08-22	4	600.00
1589	791	3	2025-08-21	1	3500.00
1590	791	7	2025-08-20	4	12000.00
1591	792	7	2025-08-28	2	12000.00
1592	792	2	2025-08-25	1	6000.00
1593	793	4	2025-09-01	3	1800.00
1594	794	4	2025-09-08	1	1800.00
1595	794	6	2025-09-08	2	600.00
1596	795	3	2025-09-10	3	3500.00
1597	797	3	2025-09-18	3	3500.00
1598	797	7	2025-09-19	2	12000.00
1599	798	7	2025-09-24	4	12000.00
1600	798	7	2025-09-22	3	12000.00
1601	799	6	2025-09-26	4	600.00
1602	800	4	2025-09-30	2	1800.00
1603	801	1	2025-07-03	2	2500.00
1604	801	3	2025-07-03	2	3500.00
1605	801	3	2025-07-02	3	3500.00
1606	803	7	2025-07-09	2	12000.00
1607	803	5	2025-07-09	2	15000.00
1608	804	3	2025-07-13	3	3500.00
1609	804	7	2025-07-12	2	12000.00
1610	806	3	2025-07-22	3	3500.00
1611	807	1	2025-07-25	1	2500.00
1612	807	5	2025-07-25	2	15000.00
1613	808	7	2025-07-28	1	12000.00
1614	808	7	2025-07-28	1	12000.00
1615	808	7	2025-07-27	3	12000.00
1616	809	2	2025-07-31	2	6000.00
1617	809	7	2025-07-31	4	12000.00
1618	810	4	2025-08-04	1	1800.00
1619	810	7	2025-08-03	1	12000.00
1620	811	6	2025-08-06	3	600.00
1621	811	1	2025-08-06	1	2500.00
1622	811	7	2025-08-06	4	12000.00
1623	812	7	2025-08-11	4	12000.00
1624	812	2	2025-08-10	1	6000.00
1625	813	7	2025-08-12	2	12000.00
1626	813	2	2025-08-13	3	6000.00
1627	813	2	2025-08-13	2	6000.00
1628	814	5	2025-08-19	2	15000.00
1629	814	6	2025-08-19	4	600.00
1630	815	6	2025-08-21	4	600.00
1631	815	7	2025-08-21	2	12000.00
1632	816	4	2025-08-25	4	1800.00
1633	816	2	2025-08-25	2	6000.00
1634	816	3	2025-08-25	1	3500.00
1635	816	3	2025-08-25	4	3500.00
1636	817	1	2025-08-30	2	2500.00
1637	817	6	2025-08-27	3	600.00
1638	817	3	2025-08-30	2	3500.00
1639	818	3	2025-09-03	2	3500.00
1640	818	3	2025-09-02	3	3500.00
1641	819	6	2025-09-08	3	600.00
1642	819	6	2025-09-07	3	600.00
1643	820	6	2025-09-12	4	600.00
1644	820	2	2025-09-12	3	6000.00
1645	820	6	2025-09-11	3	600.00
1646	821	3	2025-09-16	2	3500.00
1647	821	3	2025-09-16	3	3500.00
1648	821	5	2025-09-15	2	15000.00
1649	822	2	2025-09-24	2	6000.00
1650	822	2	2025-09-24	4	6000.00
1651	822	2	2025-09-22	2	6000.00
1652	822	4	2025-09-22	1	1800.00
1653	823	7	2025-09-25	2	12000.00
1654	823	1	2025-09-25	2	2500.00
1655	824	3	2025-09-27	3	3500.00
1656	825	1	2025-09-28	1	2500.00
1657	825	7	2025-09-28	2	12000.00
1658	825	1	2025-09-28	2	2500.00
1659	825	2	2025-09-28	3	6000.00
1660	826	3	2025-09-30	3	3500.00
1661	826	3	2025-10-01	2	3500.00
1662	827	5	2025-07-02	3	15000.00
1663	827	2	2025-07-01	3	6000.00
1664	828	5	2025-07-05	4	15000.00
1665	828	1	2025-07-05	3	2500.00
1666	828	6	2025-07-06	4	600.00
1667	830	7	2025-07-11	3	12000.00
1668	830	6	2025-07-11	1	600.00
1669	830	6	2025-07-12	2	600.00
1670	831	7	2025-07-15	1	12000.00
1671	831	2	2025-07-15	1	6000.00
1672	831	6	2025-07-15	2	600.00
1673	832	7	2025-07-17	4	12000.00
1674	832	3	2025-07-17	3	3500.00
1675	832	4	2025-07-19	3	1800.00
1676	833	6	2025-07-22	3	600.00
1677	834	3	2025-07-25	2	3500.00
1678	834	6	2025-07-25	2	600.00
1679	834	6	2025-07-25	1	600.00
1680	835	6	2025-07-27	3	600.00
1681	835	5	2025-07-27	3	15000.00
1682	835	7	2025-07-27	2	12000.00
1683	836	2	2025-07-30	2	6000.00
1684	836	6	2025-07-29	1	600.00
1685	836	7	2025-07-30	2	12000.00
1686	837	6	2025-08-05	3	600.00
1687	837	3	2025-08-02	2	3500.00
1688	838	7	2025-08-07	1	12000.00
1689	838	7	2025-08-07	4	12000.00
1690	838	5	2025-08-07	1	15000.00
1691	839	3	2025-08-10	2	3500.00
1692	839	3	2025-08-10	1	3500.00
1693	839	7	2025-08-11	2	12000.00
1694	839	5	2025-08-11	1	15000.00
1695	840	1	2025-08-14	4	2500.00
1696	841	7	2025-08-18	3	12000.00
1697	842	3	2025-08-22	2	3500.00
1698	843	7	2025-08-30	3	12000.00
1699	843	1	2025-08-30	3	2500.00
1700	844	6	2025-09-02	1	600.00
1701	845	6	2025-09-06	2	600.00
1702	845	1	2025-09-08	1	2500.00
1703	846	3	2025-09-13	4	3500.00
1704	846	2	2025-09-12	3	6000.00
1705	846	5	2025-09-12	2	15000.00
1706	847	1	2025-09-16	3	2500.00
1707	848	4	2025-09-20	2	1800.00
1708	848	1	2025-09-20	2	2500.00
1709	848	1	2025-09-21	4	2500.00
1710	848	7	2025-09-21	3	12000.00
1711	849	5	2025-09-24	1	15000.00
1712	849	7	2025-09-24	1	12000.00
1713	849	4	2025-09-24	2	1800.00
1714	850	5	2025-09-27	2	15000.00
1715	851	2	2025-09-30	4	6000.00
1716	851	6	2025-10-01	2	600.00
1717	852	5	2025-07-02	1	15000.00
1718	852	1	2025-07-02	3	2500.00
1719	853	2	2025-07-06	2	6000.00
1720	853	7	2025-07-06	4	12000.00
1721	854	5	2025-07-09	2	15000.00
1722	855	3	2025-07-14	4	3500.00
1723	856	2	2025-07-16	2	6000.00
1724	857	6	2025-07-22	3	600.00
1725	857	2	2025-07-22	4	6000.00
1726	857	3	2025-07-21	1	3500.00
1727	858	4	2025-07-28	3	1800.00
1728	858	3	2025-07-27	3	3500.00
1729	858	7	2025-07-28	2	12000.00
1730	859	3	2025-07-30	3	3500.00
1731	859	2	2025-07-30	2	6000.00
1732	859	3	2025-07-30	4	3500.00
1733	859	5	2025-08-02	4	15000.00
1734	861	7	2025-08-09	3	12000.00
1735	861	7	2025-08-12	3	12000.00
1736	861	1	2025-08-12	1	2500.00
1737	862	3	2025-08-15	2	3500.00
1738	862	1	2025-08-14	3	2500.00
1739	863	6	2025-08-18	2	600.00
1740	863	7	2025-08-17	2	12000.00
1741	864	3	2025-08-22	3	3500.00
1742	864	2	2025-08-21	1	6000.00
1743	864	6	2025-08-22	3	600.00
1744	864	5	2025-08-22	2	15000.00
1745	865	6	2025-08-24	3	600.00
1746	866	3	2025-08-27	3	3500.00
1747	866	6	2025-08-30	4	600.00
1748	866	5	2025-08-30	1	15000.00
1749	868	1	2025-09-05	3	2500.00
1750	868	4	2025-09-05	3	1800.00
1751	869	7	2025-09-08	3	12000.00
1752	869	5	2025-09-09	3	15000.00
1753	869	3	2025-09-09	3	3500.00
1754	870	5	2025-09-11	2	15000.00
1755	870	3	2025-09-12	2	3500.00
1756	870	7	2025-09-11	1	12000.00
1757	871	2	2025-09-17	3	6000.00
1758	872	5	2025-09-19	3	15000.00
1759	872	5	2025-09-20	2	15000.00
1760	873	4	2025-09-22	2	1800.00
1761	873	2	2025-09-23	3	6000.00
1762	873	7	2025-09-22	2	12000.00
1763	873	3	2025-09-23	1	3500.00
1764	874	6	2025-09-26	1	600.00
1765	874	6	2025-09-25	4	600.00
1766	874	1	2025-09-25	3	2500.00
1767	874	4	2025-09-26	2	1800.00
1768	875	4	2025-09-30	2	1800.00
1769	875	4	2025-10-01	2	1800.00
1770	876	7	2025-07-03	4	12000.00
1771	876	1	2025-07-02	1	2500.00
1772	876	7	2025-07-01	1	12000.00
1773	877	7	2025-07-05	3	12000.00
1774	877	4	2025-07-06	2	1800.00
1775	877	2	2025-07-06	3	6000.00
1776	878	6	2025-07-11	3	600.00
1777	878	5	2025-07-09	2	15000.00
1778	878	7	2025-07-12	4	12000.00
1779	878	6	2025-07-10	1	600.00
1780	879	3	2025-07-14	2	3500.00
1781	879	5	2025-07-14	4	15000.00
1782	880	3	2025-07-18	3	3500.00
1783	880	5	2025-07-18	3	15000.00
1784	880	5	2025-07-19	3	15000.00
1785	881	1	2025-07-24	4	2500.00
1786	881	5	2025-07-24	3	15000.00
1787	881	3	2025-07-23	4	3500.00
1788	882	5	2025-07-27	3	15000.00
1789	883	7	2025-07-30	3	12000.00
1790	883	7	2025-07-30	4	12000.00
1791	883	4	2025-07-30	3	1800.00
1792	885	5	2025-08-04	4	15000.00
1793	886	5	2025-08-06	1	15000.00
1794	886	3	2025-08-05	4	3500.00
1795	887	6	2025-08-09	3	600.00
1796	887	3	2025-08-08	4	3500.00
1797	887	5	2025-08-10	3	15000.00
1798	887	5	2025-08-10	2	15000.00
1799	888	1	2025-08-13	1	2500.00
1800	888	3	2025-08-13	2	3500.00
1801	888	2	2025-08-14	2	6000.00
1802	888	5	2025-08-14	1	15000.00
1803	889	7	2025-08-16	2	12000.00
1804	889	3	2025-08-16	2	3500.00
1805	889	5	2025-08-16	2	15000.00
1806	889	2	2025-08-16	4	6000.00
1807	890	1	2025-08-20	3	2500.00
1808	890	2	2025-08-19	3	6000.00
1809	890	2	2025-08-20	2	6000.00
1810	890	3	2025-08-19	2	3500.00
1811	891	5	2025-08-22	2	15000.00
1812	891	6	2025-08-23	2	600.00
1813	891	7	2025-08-23	4	12000.00
1814	892	4	2025-08-28	2	1800.00
1815	892	3	2025-08-24	3	3500.00
1816	893	2	2025-09-01	1	6000.00
1817	893	5	2025-08-31	2	15000.00
1818	893	4	2025-08-31	1	1800.00
1819	893	3	2025-09-01	1	3500.00
1820	894	1	2025-09-05	2	2500.00
1821	894	3	2025-09-06	3	3500.00
1822	894	1	2025-09-05	4	2500.00
1823	894	7	2025-09-06	3	12000.00
1824	895	3	2025-09-09	4	3500.00
1825	895	7	2025-09-10	3	12000.00
1826	897	1	2025-09-18	2	2500.00
1827	897	2	2025-09-19	2	6000.00
1828	898	6	2025-09-21	2	600.00
1829	898	1	2025-09-22	4	2500.00
1830	898	2	2025-09-22	2	6000.00
1831	898	2	2025-09-22	4	6000.00
1832	899	4	2025-09-25	3	1800.00
1833	899	5	2025-09-26	3	15000.00
1834	899	1	2025-09-25	1	2500.00
1835	900	5	2025-09-29	1	15000.00
1836	900	3	2025-09-30	3	3500.00
1837	900	6	2025-09-29	4	600.00
1838	902	2	2025-07-09	3	6000.00
1839	902	4	2025-07-09	3	1800.00
1840	903	7	2025-07-12	2	12000.00
1841	903	3	2025-07-13	4	3500.00
1842	904	4	2025-07-16	4	1800.00
1843	905	1	2025-07-19	2	2500.00
1844	906	6	2025-07-21	4	600.00
1845	906	1	2025-07-24	2	2500.00
1846	906	6	2025-07-23	3	600.00
1847	907	5	2025-07-26	2	15000.00
1848	907	5	2025-07-29	3	15000.00
1849	908	6	2025-08-02	1	600.00
1850	908	6	2025-08-02	4	600.00
1851	910	4	2025-08-09	1	1800.00
1852	910	1	2025-08-09	4	2500.00
1853	910	1	2025-08-09	3	2500.00
1854	910	5	2025-08-09	3	15000.00
1855	911	1	2025-08-13	2	2500.00
1856	911	1	2025-08-12	2	2500.00
1857	912	3	2025-08-18	3	3500.00
1858	912	1	2025-08-19	1	2500.00
1859	913	3	2025-08-21	3	3500.00
1860	914	1	2025-08-29	2	2500.00
1861	914	6	2025-08-26	2	600.00
1862	915	2	2025-09-02	1	6000.00
1863	915	2	2025-09-01	2	6000.00
1864	915	3	2025-09-03	1	3500.00
1865	916	1	2025-09-07	4	2500.00
1866	916	7	2025-09-05	4	12000.00
1867	916	7	2025-09-05	3	12000.00
1868	917	5	2025-09-09	2	15000.00
1869	917	2	2025-09-09	4	6000.00
1870	917	5	2025-09-09	3	15000.00
1871	918	2	2025-09-13	3	6000.00
1872	919	7	2025-09-19	3	12000.00
1873	919	6	2025-09-18	3	600.00
1874	920	6	2025-09-22	4	600.00
1875	920	5	2025-09-24	4	15000.00
1876	921	7	2025-09-27	3	12000.00
1877	921	1	2025-09-27	3	2500.00
1878	922	5	2025-07-01	3	15000.00
1879	924	5	2025-07-08	2	15000.00
1880	924	2	2025-07-07	2	6000.00
1881	924	4	2025-07-07	1	1800.00
1882	925	6	2025-07-10	2	600.00
1883	925	4	2025-07-10	3	1800.00
1884	925	6	2025-07-11	2	600.00
1885	926	4	2025-07-14	1	1800.00
1886	926	5	2025-07-13	4	15000.00
1887	926	5	2025-07-13	3	15000.00
1888	926	4	2025-07-13	4	1800.00
1889	927	5	2025-07-17	3	15000.00
1890	927	2	2025-07-18	2	6000.00
1891	927	4	2025-07-18	3	1800.00
1892	928	2	2025-07-24	2	6000.00
1893	928	5	2025-07-24	2	15000.00
1894	928	6	2025-07-22	3	600.00
1895	929	7	2025-07-27	2	12000.00
1896	929	2	2025-07-27	3	6000.00
1897	930	4	2025-08-01	2	1800.00
1898	930	3	2025-07-31	3	3500.00
1899	930	7	2025-07-31	4	12000.00
1900	930	4	2025-08-01	2	1800.00
1901	932	6	2025-08-08	1	600.00
1902	933	5	2025-08-12	3	15000.00
1903	933	1	2025-08-12	4	2500.00
1904	933	4	2025-08-14	1	1800.00
1905	934	3	2025-08-20	1	3500.00
1906	934	3	2025-08-21	1	3500.00
1907	935	1	2025-08-23	2	2500.00
1908	935	1	2025-08-23	2	2500.00
1909	936	2	2025-08-27	3	6000.00
1910	936	7	2025-08-28	1	12000.00
1911	936	6	2025-08-27	2	600.00
1912	937	6	2025-09-01	3	600.00
1913	937	2	2025-08-31	3	6000.00
1914	937	1	2025-09-01	3	2500.00
1915	938	5	2025-09-05	2	15000.00
1916	938	3	2025-09-05	1	3500.00
1917	938	3	2025-09-05	2	3500.00
1918	938	6	2025-09-06	1	600.00
1919	939	6	2025-09-10	2	600.00
1920	939	6	2025-09-10	3	600.00
1921	940	6	2025-09-12	2	600.00
1922	940	4	2025-09-12	2	1800.00
1923	940	3	2025-09-11	3	3500.00
1924	941	2	2025-09-15	4	6000.00
1925	941	2	2025-09-17	2	6000.00
1926	942	2	2025-09-19	3	6000.00
1927	942	2	2025-09-21	2	6000.00
1928	943	2	2025-09-27	3	6000.00
1929	944	2	2025-10-02	1	6000.00
1930	945	1	2025-07-01	2	2500.00
1931	946	2	2025-07-09	2	6000.00
1932	946	3	2025-07-09	3	3500.00
1933	946	3	2025-07-08	1	3500.00
1934	947	6	2025-07-13	3	600.00
1935	947	5	2025-07-13	4	15000.00
1936	947	5	2025-07-14	2	15000.00
1937	947	5	2025-07-13	2	15000.00
1938	948	5	2025-07-16	3	15000.00
1939	949	7	2025-07-18	3	12000.00
1940	949	3	2025-07-17	2	3500.00
1941	950	7	2025-07-20	2	12000.00
1942	950	3	2025-07-20	1	3500.00
1943	950	1	2025-07-19	4	2500.00
1944	951	1	2025-07-24	3	2500.00
1945	951	6	2025-07-24	1	600.00
1946	951	3	2025-07-25	2	3500.00
1947	951	3	2025-07-24	3	3500.00
1948	952	4	2025-07-27	3	1800.00
1949	953	5	2025-07-29	2	15000.00
1950	954	6	2025-08-03	2	600.00
1951	954	6	2025-08-04	2	600.00
1952	954	3	2025-08-03	2	3500.00
1953	955	3	2025-08-10	1	3500.00
1954	955	3	2025-08-11	2	3500.00
1955	955	1	2025-08-10	1	2500.00
1956	956	5	2025-08-14	4	15000.00
1957	956	5	2025-08-13	3	15000.00
1958	957	5	2025-08-18	3	15000.00
1959	957	4	2025-08-17	3	1800.00
1960	958	5	2025-08-22	3	15000.00
1961	958	1	2025-08-20	4	2500.00
1962	958	6	2025-08-21	4	600.00
1963	959	4	2025-08-24	1	1800.00
1964	959	6	2025-08-24	3	600.00
1965	959	1	2025-08-25	3	2500.00
1966	960	5	2025-08-28	1	15000.00
1967	960	2	2025-08-28	3	6000.00
1968	961	3	2025-08-30	3	3500.00
1969	961	4	2025-08-31	3	1800.00
1970	961	4	2025-09-02	1	1800.00
1971	961	3	2025-09-01	3	3500.00
1972	962	1	2025-09-05	1	2500.00
1973	962	6	2025-09-04	1	600.00
1974	962	6	2025-09-05	3	600.00
1975	962	6	2025-09-04	1	600.00
1976	963	6	2025-09-08	3	600.00
1977	963	6	2025-09-07	3	600.00
1978	964	3	2025-09-13	2	3500.00
1979	964	2	2025-09-12	3	6000.00
1980	965	4	2025-09-16	1	1800.00
1981	965	1	2025-09-18	2	2500.00
1982	965	4	2025-09-16	2	1800.00
1983	966	1	2025-09-24	3	2500.00
1984	967	3	2025-09-29	4	3500.00
1985	967	4	2025-09-29	3	1800.00
1986	967	2	2025-09-29	1	6000.00
1987	968	1	2025-07-01	1	2500.00
1988	968	7	2025-07-01	3	12000.00
1989	968	1	2025-07-01	3	2500.00
1990	968	3	2025-07-01	3	3500.00
1991	969	5	2025-07-04	1	15000.00
1992	969	3	2025-07-05	3	3500.00
1993	969	6	2025-07-05	3	600.00
1994	970	6	2025-07-12	3	600.00
1995	970	1	2025-07-08	2	2500.00
1996	970	4	2025-07-09	2	1800.00
1997	971	2	2025-07-14	2	6000.00
1998	971	5	2025-07-15	2	15000.00
1999	972	1	2025-07-18	2	2500.00
2000	972	4	2025-07-19	2	1800.00
2001	973	4	2025-07-22	3	1800.00
2002	973	2	2025-07-23	2	6000.00
2003	974	2	2025-07-26	1	6000.00
2004	974	4	2025-07-27	3	1800.00
2005	974	2	2025-07-27	2	6000.00
2006	974	6	2025-07-28	3	600.00
2007	975	2	2025-08-01	4	6000.00
2008	975	2	2025-07-31	2	6000.00
2009	975	6	2025-07-31	3	600.00
2010	975	1	2025-08-02	1	2500.00
2011	976	6	2025-08-08	3	600.00
2012	976	6	2025-08-07	3	600.00
2013	976	7	2025-08-07	4	12000.00
2014	976	1	2025-08-07	2	2500.00
2015	977	4	2025-08-12	4	1800.00
2016	977	2	2025-08-12	3	6000.00
2017	979	7	2025-08-16	3	12000.00
2018	979	5	2025-08-17	1	15000.00
2019	979	5	2025-08-17	1	15000.00
2020	980	5	2025-08-21	2	15000.00
2021	980	2	2025-08-22	2	6000.00
2022	981	6	2025-08-29	2	600.00
2023	981	7	2025-08-28	2	12000.00
2024	981	4	2025-08-28	4	1800.00
2025	982	5	2025-08-31	1	15000.00
2026	982	4	2025-08-31	2	1800.00
2027	983	7	2025-09-03	2	12000.00
2028	983	6	2025-09-06	3	600.00
2029	983	4	2025-09-05	3	1800.00
2030	985	6	2025-09-17	2	600.00
2031	985	2	2025-09-17	1	6000.00
2032	985	2	2025-09-19	3	6000.00
2033	989	6	2025-07-04	4	600.00
2034	991	4	2025-07-09	4	1800.00
2035	991	5	2025-07-09	3	15000.00
2036	991	5	2025-07-09	2	15000.00
2037	992	2	2025-07-11	3	6000.00
2038	993	4	2025-07-15	2	1800.00
2039	993	7	2025-07-16	2	12000.00
2040	994	1	2025-07-19	2	2500.00
2041	994	1	2025-07-19	2	2500.00
2042	994	7	2025-07-20	3	12000.00
2043	995	2	2025-07-24	2	6000.00
2044	995	5	2025-07-24	3	15000.00
2045	996	3	2025-07-28	2	3500.00
2046	998	6	2025-08-05	4	600.00
2047	998	5	2025-08-05	4	15000.00
2048	999	4	2025-08-09	1	1800.00
2049	1000	1	2025-08-14	3	2500.00
2050	1001	1	2025-08-17	3	2500.00
2051	1001	7	2025-08-21	1	12000.00
2052	1001	3	2025-08-19	1	3500.00
2053	1001	3	2025-08-19	4	3500.00
2054	1002	4	2025-08-24	2	1800.00
2055	1002	4	2025-08-24	2	1800.00
2056	1002	3	2025-08-25	3	3500.00
2057	1002	4	2025-08-23	2	1800.00
2058	1003	5	2025-08-30	1	15000.00
2059	1003	5	2025-08-30	3	15000.00
2060	1003	3	2025-08-30	3	3500.00
2061	1004	5	2025-09-03	4	15000.00
2062	1004	7	2025-09-03	3	12000.00
2063	1004	5	2025-09-03	2	15000.00
2064	1005	5	2025-09-06	4	15000.00
2065	1005	4	2025-09-09	1	1800.00
2066	1005	5	2025-09-07	3	15000.00
2067	1007	5	2025-09-15	2	15000.00
2068	1007	2	2025-09-12	2	6000.00
2069	1007	2	2025-09-13	4	6000.00
2070	1007	6	2025-09-14	4	600.00
2071	1008	4	2025-09-18	2	1800.00
2072	1008	2	2025-09-17	1	6000.00
2073	1009	5	2025-09-21	3	15000.00
2074	1009	1	2025-09-21	1	2500.00
2075	1009	3	2025-09-21	1	3500.00
2076	1010	4	2025-09-25	3	1800.00
2077	1010	7	2025-09-25	3	12000.00
2078	1010	4	2025-09-25	3	1800.00
2079	1013	4	2025-07-06	3	1800.00
2080	1013	1	2025-07-05	2	2500.00
2081	1013	3	2025-07-04	1	3500.00
2082	1014	2	2025-07-12	3	6000.00
2083	1014	6	2025-07-11	3	600.00
2084	1015	2	2025-07-18	3	6000.00
2085	1015	1	2025-07-18	3	2500.00
2086	1015	4	2025-07-18	2	1800.00
2087	1015	5	2025-07-18	4	15000.00
2088	1016	2	2025-07-21	2	6000.00
2089	1017	4	2025-07-28	2	1800.00
2090	1017	6	2025-07-28	4	600.00
2091	1017	3	2025-07-27	4	3500.00
2092	1018	6	2025-07-30	1	600.00
2093	1018	3	2025-07-30	4	3500.00
2094	1020	1	2025-08-08	3	2500.00
2095	1020	1	2025-08-09	1	2500.00
2096	1021	3	2025-08-14	1	3500.00
2097	1021	5	2025-08-10	1	15000.00
2098	1021	6	2025-08-13	4	600.00
2099	1021	6	2025-08-14	4	600.00
2100	1022	7	2025-08-17	4	12000.00
2101	1023	5	2025-08-20	1	15000.00
2102	1024	7	2025-08-23	4	12000.00
2103	1024	5	2025-08-24	2	15000.00
2104	1025	5	2025-08-29	2	15000.00
2105	1025	2	2025-08-30	1	6000.00
2106	1026	7	2025-09-01	3	12000.00
2107	1026	5	2025-09-02	2	15000.00
2108	1026	7	2025-09-02	2	12000.00
2109	1027	2	2025-09-08	3	6000.00
2110	1027	4	2025-09-08	3	1800.00
2111	1027	3	2025-09-08	1	3500.00
2112	1028	1	2025-09-10	1	2500.00
2113	1028	2	2025-09-10	3	6000.00
2114	1028	4	2025-09-10	3	1800.00
2115	1029	5	2025-09-13	3	15000.00
2116	1030	7	2025-09-16	4	12000.00
2117	1031	2	2025-09-20	1	6000.00
2118	1031	1	2025-09-19	1	2500.00
2119	1032	1	2025-09-23	2	2500.00
2120	1032	7	2025-09-25	3	12000.00
2121	1033	3	2025-09-28	1	3500.00
2122	1033	2	2025-09-28	2	6000.00
2123	1034	7	2025-07-01	1	12000.00
2124	1034	7	2025-07-02	4	12000.00
2125	1035	6	2025-07-05	3	600.00
2126	1035	1	2025-07-05	4	2500.00
2127	1035	1	2025-07-05	3	2500.00
2128	1037	2	2025-07-10	3	6000.00
2129	1037	2	2025-07-10	1	6000.00
2130	1037	2	2025-07-11	3	6000.00
2131	1038	3	2025-07-16	3	3500.00
2132	1038	7	2025-07-16	3	12000.00
2133	1041	7	2025-07-24	2	12000.00
2134	1041	6	2025-07-24	4	600.00
2135	1041	2	2025-07-23	3	6000.00
2136	1041	1	2025-07-23	4	2500.00
2137	1042	7	2025-07-27	1	12000.00
2138	1042	1	2025-07-26	4	2500.00
2139	1042	2	2025-07-26	1	6000.00
2140	1043	5	2025-07-30	2	15000.00
2141	1043	1	2025-07-31	1	2500.00
2142	1044	1	2025-08-02	1	2500.00
2143	1044	1	2025-08-03	3	2500.00
2144	1044	6	2025-08-02	2	600.00
2145	1045	7	2025-08-06	2	12000.00
2146	1045	7	2025-08-07	3	12000.00
2147	1045	2	2025-08-07	3	6000.00
2148	1046	1	2025-08-10	3	2500.00
2149	1046	7	2025-08-11	4	12000.00
2150	1047	3	2025-08-15	2	3500.00
2151	1048	7	2025-08-19	2	12000.00
2152	1048	3	2025-08-19	3	3500.00
2153	1048	3	2025-08-18	4	3500.00
2154	1050	6	2025-08-27	3	600.00
2155	1050	4	2025-08-25	4	1800.00
2156	1051	1	2025-08-29	2	2500.00
2157	1052	3	2025-09-02	2	3500.00
2158	1052	6	2025-09-02	3	600.00
2159	1053	3	2025-09-06	1	3500.00
2160	1054	1	2025-09-10	4	2500.00
2161	1054	1	2025-09-11	2	2500.00
2162	1055	4	2025-09-15	2	1800.00
2163	1055	1	2025-09-17	2	2500.00
2164	1055	3	2025-09-15	2	3500.00
2165	1056	7	2025-09-19	3	12000.00
2166	1056	6	2025-09-18	3	600.00
2167	1056	7	2025-09-19	2	12000.00
2168	1056	5	2025-09-19	4	15000.00
2169	1057	3	2025-09-23	3	3500.00
2170	1057	3	2025-09-23	3	3500.00
2171	1058	3	2025-09-27	3	3500.00
2172	1058	5	2025-09-29	4	15000.00
2173	1059	6	2025-07-02	2	600.00
2174	1060	7	2025-07-05	2	12000.00
2175	1060	3	2025-07-05	2	3500.00
2176	1060	7	2025-07-05	3	12000.00
2177	1061	2	2025-07-08	3	6000.00
2178	1061	2	2025-07-08	4	6000.00
2179	1061	2	2025-07-08	2	6000.00
2180	1061	3	2025-07-08	3	3500.00
2181	1062	4	2025-07-11	3	1800.00
2182	1062	6	2025-07-11	3	600.00
2183	1062	7	2025-07-12	2	12000.00
2184	1063	3	2025-07-14	3	3500.00
2185	1063	7	2025-07-14	4	12000.00
2186	1064	5	2025-07-16	3	15000.00
2187	1064	6	2025-07-16	4	600.00
2188	1064	7	2025-07-16	4	12000.00
2189	1064	7	2025-07-16	1	12000.00
2190	1065	7	2025-07-19	2	12000.00
2191	1066	1	2025-07-21	4	2500.00
2192	1066	4	2025-07-21	1	1800.00
2193	1068	6	2025-07-29	4	600.00
2194	1068	6	2025-07-28	4	600.00
2195	1069	3	2025-08-01	1	3500.00
2196	1069	3	2025-08-02	3	3500.00
2197	1069	3	2025-08-02	3	3500.00
2198	1070	4	2025-08-06	4	1800.00
2199	1070	5	2025-08-05	2	15000.00
2200	1071	1	2025-08-08	3	2500.00
2201	1071	2	2025-08-08	2	6000.00
2202	1071	3	2025-08-08	2	3500.00
2203	1071	3	2025-08-08	2	3500.00
2204	1072	6	2025-08-09	1	600.00
2205	1072	2	2025-08-10	4	6000.00
2206	1072	3	2025-08-09	3	3500.00
2207	1073	7	2025-08-12	4	12000.00
2208	1073	2	2025-08-12	3	6000.00
2209	1073	1	2025-08-14	2	2500.00
2210	1074	7	2025-08-18	1	12000.00
2211	1075	6	2025-08-23	4	600.00
2212	1075	2	2025-08-24	3	6000.00
2213	1075	4	2025-08-24	2	1800.00
2214	1076	1	2025-08-26	2	2500.00
2215	1076	4	2025-08-26	3	1800.00
2216	1077	7	2025-08-30	2	12000.00
2217	1077	2	2025-08-29	1	6000.00
2218	1077	3	2025-08-31	3	3500.00
2219	1077	7	2025-08-29	2	12000.00
2220	1078	5	2025-09-03	4	15000.00
2221	1078	6	2025-09-04	1	600.00
2222	1078	3	2025-09-04	2	3500.00
2223	1079	3	2025-09-10	3	3500.00
2224	1079	1	2025-09-10	2	2500.00
2225	1079	7	2025-09-10	3	12000.00
2226	1080	6	2025-09-16	2	600.00
2227	1080	2	2025-09-16	4	6000.00
2228	1080	5	2025-09-14	2	15000.00
2229	1081	6	2025-09-21	2	600.00
2230	1081	3	2025-09-21	3	3500.00
2231	1081	2	2025-09-20	4	6000.00
2232	1083	6	2025-09-30	3	600.00
2233	1083	2	2025-09-30	2	6000.00
2234	1083	7	2025-10-02	2	12000.00
2235	1085	1	2025-07-04	3	2500.00
2236	1085	7	2025-07-04	2	12000.00
2237	1085	3	2025-07-05	3	3500.00
2238	1086	6	2025-07-11	1	600.00
2239	1087	2	2025-07-14	3	6000.00
2240	1087	2	2025-07-14	3	6000.00
2241	1088	4	2025-07-18	3	1800.00
2242	1088	4	2025-07-18	2	1800.00
2243	1089	6	2025-07-21	1	600.00
2244	1089	5	2025-07-22	3	15000.00
2245	1090	4	2025-07-24	4	1800.00
2246	1091	2	2025-07-29	2	6000.00
2247	1092	3	2025-08-01	3	3500.00
2248	1092	5	2025-08-01	2	15000.00
2249	1092	5	2025-08-01	3	15000.00
2250	1093	2	2025-08-03	3	6000.00
2251	1095	4	2025-08-10	2	1800.00
2252	1095	6	2025-08-09	2	600.00
2253	1096	3	2025-08-12	2	3500.00
2254	1096	1	2025-08-12	4	2500.00
2255	1097	2	2025-08-16	3	6000.00
2256	1097	3	2025-08-16	2	3500.00
2257	1097	1	2025-08-16	4	2500.00
2258	1097	2	2025-08-16	3	6000.00
2259	1098	5	2025-08-17	3	15000.00
2260	1099	7	2025-08-19	3	12000.00
2261	1099	3	2025-08-19	3	3500.00
2262	1100	4	2025-08-21	3	1800.00
2263	1100	7	2025-08-21	1	12000.00
2264	1101	1	2025-08-25	3	2500.00
2265	1102	7	2025-08-31	3	12000.00
2266	1102	6	2025-08-31	4	600.00
2267	1103	7	2025-09-07	2	12000.00
2268	1103	7	2025-09-08	3	12000.00
2269	1103	2	2025-09-06	1	6000.00
2270	1103	4	2025-09-05	2	1800.00
2271	1107	7	2025-09-26	1	12000.00
2272	1108	4	2025-09-29	4	1800.00
2273	1108	4	2025-09-29	2	1800.00
2274	1108	2	2025-09-29	4	6000.00
2275	1108	6	2025-09-30	2	600.00
2276	1109	1	2025-07-01	3	2500.00
2277	1110	5	2025-07-04	1	15000.00
2278	1110	5	2025-07-05	3	15000.00
2279	1111	2	2025-07-09	3	6000.00
2280	1111	5	2025-07-08	3	15000.00
2281	1111	4	2025-07-09	2	1800.00
2282	1112	3	2025-07-14	2	3500.00
2283	1112	5	2025-07-13	1	15000.00
2284	1112	6	2025-07-13	1	600.00
2285	1113	2	2025-07-17	2	6000.00
2286	1113	1	2025-07-17	1	2500.00
2287	1114	5	2025-07-20	1	15000.00
2288	1114	7	2025-07-21	2	12000.00
2289	1114	5	2025-07-22	3	15000.00
2290	1115	1	2025-07-24	2	2500.00
2291	1116	1	2025-07-29	3	2500.00
2292	1117	7	2025-07-30	2	12000.00
2293	1118	1	2025-08-06	1	2500.00
2294	1118	3	2025-08-05	2	3500.00
2295	1118	5	2025-08-05	2	15000.00
2296	1118	6	2025-08-07	2	600.00
2297	1119	7	2025-08-10	4	12000.00
2298	1119	7	2025-08-09	4	12000.00
2299	1119	1	2025-08-09	4	2500.00
2300	1119	3	2025-08-09	4	3500.00
2301	1121	1	2025-08-13	2	2500.00
2302	1121	7	2025-08-13	3	12000.00
2303	1121	7	2025-08-13	4	12000.00
2304	1121	5	2025-08-13	2	15000.00
2305	1124	4	2025-08-26	2	1800.00
2306	1124	5	2025-08-26	2	15000.00
2307	1124	2	2025-08-26	2	6000.00
2308	1125	5	2025-08-28	3	15000.00
2309	1126	3	2025-08-31	1	3500.00
2310	1126	7	2025-09-01	4	12000.00
2311	1126	5	2025-08-31	4	15000.00
2312	1126	4	2025-08-31	2	1800.00
2313	1127	1	2025-09-04	2	2500.00
2314	1127	1	2025-09-06	2	2500.00
2315	1127	3	2025-09-04	3	3500.00
2316	1128	5	2025-09-09	2	15000.00
2317	1128	4	2025-09-08	2	1800.00
2318	1129	4	2025-09-11	3	1800.00
2319	1132	3	2025-09-21	4	3500.00
2320	1132	6	2025-09-21	3	600.00
2321	1133	3	2025-09-27	3	3500.00
2322	1134	5	2025-09-30	1	15000.00
2323	1134	5	2025-09-30	2	15000.00
2324	1135	6	2025-07-02	3	600.00
2325	1135	6	2025-07-04	3	600.00
2326	1135	5	2025-07-02	2	15000.00
2327	1136	7	2025-07-06	2	12000.00
2328	1136	3	2025-07-05	2	3500.00
2329	1136	6	2025-07-06	3	600.00
2330	1136	2	2025-07-05	4	6000.00
2331	1137	2	2025-07-10	2	6000.00
2332	1137	4	2025-07-09	2	1800.00
2333	1137	7	2025-07-09	3	12000.00
2334	1137	7	2025-07-09	2	12000.00
2335	1138	6	2025-07-12	1	600.00
2336	1138	1	2025-07-13	3	2500.00
2337	1138	7	2025-07-14	2	12000.00
2338	1138	7	2025-07-12	2	12000.00
2339	1139	4	2025-07-19	4	1800.00
2340	1140	7	2025-07-25	2	12000.00
2341	1140	6	2025-07-24	2	600.00
2342	1140	7	2025-07-25	3	12000.00
2343	1141	3	2025-07-28	3	3500.00
2344	1141	6	2025-07-28	1	600.00
2345	1142	2	2025-08-02	3	6000.00
2346	1143	1	2025-08-05	2	2500.00
2347	1143	7	2025-08-05	2	12000.00
2348	1143	2	2025-08-05	3	6000.00
2349	1144	1	2025-08-07	2	2500.00
2350	1145	7	2025-08-11	2	12000.00
2351	1145	1	2025-08-10	4	2500.00
2352	1145	5	2025-08-11	3	15000.00
2353	1146	3	2025-08-15	2	3500.00
2354	1146	2	2025-08-16	4	6000.00
2355	1147	3	2025-08-19	2	3500.00
2356	1147	3	2025-08-19	2	3500.00
2357	1147	1	2025-08-19	3	2500.00
2358	1148	3	2025-08-22	2	3500.00
2359	1149	6	2025-08-26	3	600.00
2360	1150	6	2025-08-30	3	600.00
2361	1150	7	2025-08-29	3	12000.00
2362	1151	6	2025-09-01	4	600.00
2363	1152	6	2025-09-08	4	600.00
2364	1152	4	2025-09-06	2	1800.00
2365	1153	2	2025-09-16	1	6000.00
2366	1154	3	2025-09-20	4	3500.00
2367	1154	2	2025-09-20	3	6000.00
2368	1154	4	2025-09-20	2	1800.00
2369	1154	4	2025-09-20	1	1800.00
2370	1155	7	2025-09-26	2	12000.00
2371	1155	1	2025-09-24	2	2500.00
2372	1156	7	2025-10-02	2	12000.00
2373	1156	2	2025-10-02	2	6000.00
2374	1156	4	2025-09-30	4	1800.00
2375	1157	7	2025-07-01	4	12000.00
2376	1158	7	2025-07-07	2	12000.00
2377	1158	7	2025-07-06	3	12000.00
2378	1158	3	2025-07-06	3	3500.00
2379	1159	6	2025-07-12	1	600.00
2380	1159	3	2025-07-10	3	3500.00
2381	1159	4	2025-07-12	2	1800.00
2382	1160	7	2025-07-15	4	12000.00
2383	1160	7	2025-07-15	2	12000.00
2384	1160	2	2025-07-16	1	6000.00
2385	1161	3	2025-07-20	1	3500.00
2386	1161	5	2025-07-19	1	15000.00
2387	1162	2	2025-07-23	1	6000.00
2388	1162	5	2025-07-23	2	15000.00
2389	1164	2	2025-07-27	4	6000.00
2390	1165	1	2025-07-31	4	2500.00
2391	1166	4	2025-08-02	2	1800.00
2392	1166	6	2025-08-04	3	600.00
2393	1166	7	2025-08-01	4	12000.00
2394	1167	6	2025-08-06	1	600.00
2395	1168	1	2025-08-12	3	2500.00
2396	1169	1	2025-08-17	3	2500.00
2397	1169	7	2025-08-17	2	12000.00
2398	1169	5	2025-08-15	4	15000.00
2399	1170	5	2025-08-22	4	15000.00
2400	1170	1	2025-08-23	2	2500.00
2401	1170	7	2025-08-22	2	12000.00
2402	1171	7	2025-08-28	3	12000.00
2403	1171	6	2025-08-28	3	600.00
2404	1171	3	2025-08-28	3	3500.00
2405	1172	2	2025-09-01	3	6000.00
2406	1173	2	2025-09-03	3	6000.00
2407	1174	3	2025-09-06	3	3500.00
2408	1174	6	2025-09-06	4	600.00
2409	1174	5	2025-09-07	3	15000.00
2410	1175	4	2025-09-11	2	1800.00
2411	1175	5	2025-09-10	4	15000.00
2412	1176	6	2025-09-16	2	600.00
2413	1177	1	2025-09-20	3	2500.00
2414	1177	1	2025-09-20	4	2500.00
2415	1177	4	2025-09-20	2	1800.00
2416	1177	4	2025-09-20	1	1800.00
2417	1178	3	2025-09-22	2	3500.00
2418	1178	5	2025-09-22	1	15000.00
2419	1178	1	2025-09-22	4	2500.00
2420	1178	5	2025-09-22	3	15000.00
2421	1180	3	2025-10-01	4	3500.00
2422	1180	7	2025-09-30	1	12000.00
2423	1180	4	2025-10-02	1	1800.00
2424	1180	4	2025-10-02	2	1800.00
2425	1181	3	2025-07-01	2	3500.00
2426	1181	3	2025-07-01	2	3500.00
2427	1181	7	2025-07-01	2	12000.00
2428	1182	7	2025-07-04	2	12000.00
2429	1182	4	2025-07-05	3	1800.00
2430	1184	4	2025-07-13	1	1800.00
2431	1184	4	2025-07-13	2	1800.00
2432	1184	2	2025-07-13	3	6000.00
2433	1185	3	2025-07-18	2	3500.00
2434	1185	4	2025-07-16	2	1800.00
2435	1185	6	2025-07-18	3	600.00
2436	1186	4	2025-07-21	2	1800.00
2437	1187	4	2025-07-26	4	1800.00
2438	1187	1	2025-07-26	2	2500.00
2439	1187	4	2025-07-26	4	1800.00
2440	1187	1	2025-07-26	4	2500.00
2441	1188	4	2025-07-29	3	1800.00
2442	1188	5	2025-07-29	4	15000.00
2443	1188	5	2025-07-29	2	15000.00
2444	1189	5	2025-07-31	3	15000.00
2445	1190	6	2025-08-05	2	600.00
2446	1191	6	2025-08-07	2	600.00
2447	1192	7	2025-08-14	1	12000.00
2448	1192	2	2025-08-15	3	6000.00
2449	1192	4	2025-08-14	3	1800.00
2450	1194	6	2025-08-21	2	600.00
2451	1194	2	2025-08-21	3	6000.00
2452	1194	1	2025-08-20	4	2500.00
2453	1194	2	2025-08-20	1	6000.00
2454	1195	1	2025-08-25	2	2500.00
2455	1195	4	2025-08-24	3	1800.00
2456	1195	7	2025-08-26	3	12000.00
2457	1196	3	2025-08-30	4	3500.00
2458	1198	1	2025-09-05	3	2500.00
2459	1199	4	2025-09-10	2	1800.00
2460	1199	2	2025-09-09	3	6000.00
2461	1200	5	2025-09-14	2	15000.00
2462	1200	7	2025-09-14	3	12000.00
2463	1201	3	2025-09-16	2	3500.00
2464	1202	1	2025-09-19	2	2500.00
2465	1202	7	2025-09-19	1	12000.00
2466	1203	2	2025-09-25	1	6000.00
2467	1203	7	2025-09-23	3	12000.00
2468	1203	3	2025-09-22	3	3500.00
2469	1203	4	2025-09-24	4	1800.00
2470	1204	4	2025-09-29	3	1800.00
2471	1204	2	2025-09-30	3	6000.00
2472	1205	4	2025-07-01	3	1800.00
2473	1205	4	2025-07-01	1	1800.00
2474	1205	2	2025-07-01	3	6000.00
2475	1206	7	2025-07-04	4	12000.00
2476	1206	7	2025-07-06	1	12000.00
2477	1206	5	2025-07-06	4	15000.00
2478	1207	5	2025-07-09	2	15000.00
2479	1207	6	2025-07-10	1	600.00
2480	1208	4	2025-07-15	3	1800.00
2481	1208	2	2025-07-15	3	6000.00
2482	1208	6	2025-07-14	2	600.00
2483	1208	5	2025-07-16	4	15000.00
2484	1209	4	2025-07-20	2	1800.00
2485	1209	3	2025-07-20	3	3500.00
2486	1209	1	2025-07-21	3	2500.00
2487	1210	4	2025-07-26	2	1800.00
2488	1211	5	2025-07-29	2	15000.00
2489	1211	5	2025-07-28	1	15000.00
2490	1211	5	2025-07-28	3	15000.00
2491	1213	7	2025-08-04	3	12000.00
2492	1214	2	2025-08-09	2	6000.00
2493	1214	6	2025-08-09	1	600.00
2494	1215	2	2025-08-11	3	6000.00
2495	1215	1	2025-08-12	2	2500.00
2496	1216	1	2025-08-16	1	2500.00
2497	1216	2	2025-08-14	4	6000.00
2498	1216	3	2025-08-14	4	3500.00
2499	1217	2	2025-08-18	3	6000.00
2500	1217	1	2025-08-18	2	2500.00
2501	1217	4	2025-08-17	4	1800.00
2502	1217	7	2025-08-18	2	12000.00
2503	1218	1	2025-08-22	3	2500.00
2504	1218	4	2025-08-21	2	1800.00
2505	1218	3	2025-08-21	1	3500.00
2506	1218	6	2025-08-22	2	600.00
2507	1220	3	2025-08-25	1	3500.00
2508	1220	2	2025-08-25	3	6000.00
2509	1221	4	2025-08-29	3	1800.00
2510	1221	2	2025-08-28	2	6000.00
2511	1222	5	2025-08-30	3	15000.00
2512	1222	1	2025-08-31	2	2500.00
2513	1222	2	2025-08-30	2	6000.00
2514	1223	2	2025-09-04	2	6000.00
2515	1223	5	2025-09-05	2	15000.00
2516	1223	2	2025-09-03	2	6000.00
2517	1225	1	2025-09-14	2	2500.00
2518	1225	5	2025-09-14	2	15000.00
2519	1225	2	2025-09-14	3	6000.00
2520	1225	1	2025-09-14	1	2500.00
2521	1226	5	2025-09-18	3	15000.00
2522	1226	1	2025-09-18	2	2500.00
2523	1226	3	2025-09-18	2	3500.00
2524	1227	7	2025-09-21	4	12000.00
2525	1227	4	2025-09-20	3	1800.00
2526	1228	1	2025-09-25	4	2500.00
2527	1229	7	2025-09-28	3	12000.00
2528	1229	7	2025-09-29	1	12000.00
2529	1229	5	2025-09-28	4	15000.00
2530	1230	7	2025-07-01	3	12000.00
2531	1232	3	2025-07-11	2	3500.00
2532	1232	1	2025-07-12	3	2500.00
2533	1232	5	2025-07-11	4	15000.00
2534	1233	4	2025-07-16	2	1800.00
2535	1233	3	2025-07-17	2	3500.00
2536	1233	5	2025-07-17	2	15000.00
2537	1234	1	2025-07-21	2	2500.00
2538	1234	7	2025-07-22	1	12000.00
2539	1234	2	2025-07-21	3	6000.00
2540	1234	3	2025-07-21	3	3500.00
2541	1236	7	2025-07-29	1	12000.00
2542	1236	5	2025-07-31	2	15000.00
2543	1236	7	2025-07-29	1	12000.00
2544	1237	1	2025-08-02	4	2500.00
2545	1237	1	2025-08-02	2	2500.00
2546	1237	5	2025-08-02	3	15000.00
2547	1238	3	2025-08-06	2	3500.00
2548	1239	1	2025-08-12	4	2500.00
2549	1239	3	2025-08-14	1	3500.00
2550	1239	5	2025-08-12	1	15000.00
2551	1240	4	2025-08-19	3	1800.00
2552	1240	6	2025-08-18	2	600.00
2553	1240	4	2025-08-17	2	1800.00
2554	1242	7	2025-08-26	2	12000.00
2555	1244	4	2025-09-06	2	1800.00
2556	1245	6	2025-09-08	4	600.00
2557	1245	4	2025-09-08	2	1800.00
2558	1246	4	2025-09-14	4	1800.00
2559	1246	4	2025-09-15	3	1800.00
2560	1247	5	2025-09-19	3	15000.00
2561	1248	6	2025-09-25	1	600.00
2562	1248	6	2025-09-26	2	600.00
2563	1248	7	2025-09-24	2	12000.00
2564	1248	7	2025-09-25	3	12000.00
2565	1249	4	2025-09-30	4	1800.00
2566	1249	3	2025-09-27	3	3500.00
2567	1250	7	2025-07-02	2	12000.00
2568	1250	2	2025-07-02	2	6000.00
2569	1251	6	2025-07-06	3	600.00
2570	1251	3	2025-07-06	3	3500.00
2571	1251	6	2025-07-05	3	600.00
2572	1251	5	2025-07-06	1	15000.00
2573	1252	5	2025-07-09	3	15000.00
2574	1253	6	2025-07-12	3	600.00
2575	1253	7	2025-07-12	1	12000.00
2576	1254	6	2025-07-16	1	600.00
2577	1254	5	2025-07-16	2	15000.00
2578	1254	3	2025-07-16	3	3500.00
2579	1255	5	2025-07-21	1	15000.00
2580	1256	5	2025-07-23	3	15000.00
2581	1258	2	2025-08-02	3	6000.00
2582	1258	4	2025-08-01	1	1800.00
2583	1258	3	2025-08-01	1	3500.00
2584	1259	4	2025-08-06	2	1800.00
2585	1259	5	2025-08-06	3	15000.00
2586	1259	7	2025-08-05	3	12000.00
2587	1260	7	2025-08-12	4	12000.00
2588	1260	7	2025-08-12	3	12000.00
2589	1261	1	2025-08-17	2	2500.00
2590	1261	7	2025-08-17	1	12000.00
2591	1261	6	2025-08-17	3	600.00
2592	1263	6	2025-08-22	3	600.00
2593	1263	2	2025-08-22	3	6000.00
2594	1264	6	2025-08-23	3	600.00
2595	1264	6	2025-08-23	3	600.00
2596	1265	2	2025-08-27	3	6000.00
2597	1265	7	2025-08-26	2	12000.00
2598	1265	5	2025-08-26	3	15000.00
2599	1266	2	2025-08-30	2	6000.00
2600	1266	4	2025-08-30	4	1800.00
2601	1266	3	2025-08-31	3	3500.00
2602	1266	5	2025-08-30	4	15000.00
2603	1267	5	2025-09-03	2	15000.00
2604	1267	1	2025-09-03	4	2500.00
2605	1267	6	2025-09-03	3	600.00
2606	1268	6	2025-09-08	2	600.00
2607	1268	5	2025-09-09	3	15000.00
2608	1268	3	2025-09-10	2	3500.00
2609	1269	2	2025-09-13	3	6000.00
2610	1270	3	2025-09-16	1	3500.00
2611	1270	1	2025-09-16	1	2500.00
2612	1270	1	2025-09-16	2	2500.00
2613	1270	7	2025-09-16	2	12000.00
2614	1271	7	2025-09-18	3	12000.00
2615	1271	1	2025-09-18	2	2500.00
2616	1272	3	2025-09-23	4	3500.00
2617	1272	4	2025-09-23	2	1800.00
2618	1272	6	2025-09-22	3	600.00
2619	1274	6	2025-10-03	3	600.00
2620	1275	5	2025-07-01	2	15000.00
2621	1275	4	2025-07-01	2	1800.00
2622	1275	6	2025-07-02	4	600.00
2623	1275	6	2025-07-01	1	600.00
2624	1276	5	2025-07-06	3	15000.00
2625	1277	1	2025-07-09	4	2500.00
2626	1278	6	2025-07-14	3	600.00
2627	1278	6	2025-07-13	1	600.00
2628	1278	6	2025-07-12	4	600.00
2629	1278	6	2025-07-11	3	600.00
2630	1279	4	2025-07-17	4	1800.00
2631	1279	2	2025-07-18	1	6000.00
2632	1279	5	2025-07-17	4	15000.00
2633	1280	2	2025-07-24	2	6000.00
2634	1280	1	2025-07-22	3	2500.00
2635	1280	7	2025-07-23	1	12000.00
2636	1281	7	2025-07-25	1	12000.00
2637	1281	3	2025-07-25	4	3500.00
2638	1282	2	2025-07-28	3	6000.00
2639	1282	7	2025-07-28	3	12000.00
2640	1282	1	2025-07-29	4	2500.00
2641	1284	5	2025-08-06	4	15000.00
2642	1284	2	2025-08-04	1	6000.00
2643	1284	6	2025-08-04	3	600.00
2644	1285	3	2025-08-09	3	3500.00
2645	1286	7	2025-08-17	3	12000.00
2646	1287	1	2025-08-20	4	2500.00
2647	1287	7	2025-08-20	4	12000.00
2648	1287	2	2025-08-21	4	6000.00
2649	1288	6	2025-08-26	3	600.00
2650	1289	5	2025-08-28	3	15000.00
2651	1289	1	2025-08-28	1	2500.00
2652	1289	6	2025-08-30	2	600.00
2653	1289	7	2025-08-28	2	12000.00
2654	1290	7	2025-09-01	3	12000.00
2655	1291	5	2025-09-04	3	15000.00
2656	1291	2	2025-09-04	3	6000.00
2657	1291	1	2025-09-04	2	2500.00
2658	1292	4	2025-09-06	3	1800.00
2659	1293	7	2025-09-12	2	12000.00
2660	1293	4	2025-09-10	2	1800.00
2661	1294	3	2025-09-16	2	3500.00
2662	1294	3	2025-09-15	2	3500.00
2663	1295	2	2025-09-20	2	6000.00
2664	1295	2	2025-09-20	2	6000.00
2665	1295	5	2025-09-20	3	15000.00
2666	1297	4	2025-09-27	1	1800.00
2667	1297	5	2025-09-27	2	15000.00
2668	1297	1	2025-09-25	3	2500.00
2669	1298	7	2025-10-01	3	12000.00
2670	1298	3	2025-10-01	2	3500.00
2671	1298	6	2025-10-01	1	600.00
2672	1300	4	2025-07-05	1	1800.00
2673	1300	3	2025-07-06	3	3500.00
2674	1300	7	2025-07-05	2	12000.00
2675	1301	6	2025-07-07	2	600.00
2676	1301	2	2025-07-07	4	6000.00
2677	1301	1	2025-07-07	3	2500.00
2678	1302	5	2025-07-12	2	15000.00
2679	1303	2	2025-07-17	1	6000.00
2680	1303	5	2025-07-16	3	15000.00
2681	1303	1	2025-07-17	1	2500.00
2682	1303	7	2025-07-17	2	12000.00
2683	1304	5	2025-07-19	3	15000.00
2684	1305	3	2025-07-21	1	3500.00
2685	1306	2	2025-07-29	2	6000.00
2686	1306	2	2025-07-28	2	6000.00
2687	1307	6	2025-07-31	4	600.00
2688	1307	2	2025-08-01	4	6000.00
2689	1307	4	2025-07-31	3	1800.00
2690	1307	7	2025-08-01	3	12000.00
2691	1308	5	2025-08-04	2	15000.00
2692	1308	2	2025-08-03	1	6000.00
2693	1310	4	2025-08-11	3	1800.00
2694	1310	5	2025-08-13	3	15000.00
2695	1310	7	2025-08-12	2	12000.00
2696	1312	6	2025-08-21	2	600.00
2697	1312	3	2025-08-24	2	3500.00
2698	1313	5	2025-08-29	1	15000.00
2699	1313	5	2025-08-29	2	15000.00
2700	1313	7	2025-08-29	4	12000.00
2701	1313	5	2025-08-28	2	15000.00
2702	1314	3	2025-09-05	1	3500.00
2703	1314	5	2025-09-04	3	15000.00
2704	1314	6	2025-09-04	3	600.00
2705	1315	1	2025-09-09	3	2500.00
2706	1315	3	2025-09-08	1	3500.00
2707	1315	6	2025-09-10	3	600.00
2708	1316	2	2025-09-13	3	6000.00
2709	1316	5	2025-09-12	1	15000.00
2710	1316	4	2025-09-13	3	1800.00
2711	1316	2	2025-09-12	3	6000.00
2712	1317	3	2025-09-18	4	3500.00
2713	1317	3	2025-09-19	3	3500.00
2714	1317	5	2025-09-17	3	15000.00
2715	1317	7	2025-09-19	1	12000.00
2716	1318	5	2025-09-22	2	15000.00
2717	1319	3	2025-09-27	2	3500.00
2718	1320	7	2025-10-01	3	12000.00
2719	1321	6	2025-07-04	3	600.00
2720	1322	1	2025-07-08	4	2500.00
2721	1322	2	2025-07-08	3	6000.00
2722	1323	3	2025-07-12	4	3500.00
2723	1323	3	2025-07-12	2	3500.00
2724	1323	1	2025-07-12	3	2500.00
2725	1323	7	2025-07-11	3	12000.00
2726	1324	1	2025-07-17	2	2500.00
2727	1325	1	2025-07-24	2	2500.00
2728	1326	7	2025-07-26	3	12000.00
2729	1326	7	2025-07-27	1	12000.00
2730	1326	3	2025-07-28	3	3500.00
2731	1328	7	2025-08-05	2	12000.00
2732	1328	1	2025-08-05	3	2500.00
2733	1329	5	2025-08-07	2	15000.00
2734	1329	7	2025-08-07	4	12000.00
2735	1329	2	2025-08-07	1	6000.00
2736	1330	5	2025-08-11	3	15000.00
2737	1330	6	2025-08-12	2	600.00
2738	1330	2	2025-08-10	2	6000.00
2739	1330	4	2025-08-13	4	1800.00
2740	1331	4	2025-08-16	2	1800.00
2741	1331	1	2025-08-17	2	2500.00
2742	1332	7	2025-08-22	3	12000.00
2743	1332	1	2025-08-22	4	2500.00
2744	1332	5	2025-08-22	3	15000.00
2745	1334	4	2025-08-30	4	1800.00
2746	1334	7	2025-08-30	2	12000.00
2747	1334	2	2025-08-30	2	6000.00
2748	1335	1	2025-08-31	2	2500.00
2749	1335	5	2025-09-01	2	15000.00
2750	1335	4	2025-08-31	2	1800.00
2751	1336	1	2025-09-04	1	2500.00
2752	1336	6	2025-09-04	4	600.00
2753	1336	5	2025-09-05	2	15000.00
2754	1336	5	2025-09-06	2	15000.00
2755	1337	2	2025-09-08	3	6000.00
2756	1338	3	2025-09-17	3	3500.00
2757	1338	4	2025-09-16	2	1800.00
2758	1338	2	2025-09-15	4	6000.00
2759	1338	6	2025-09-15	4	600.00
2760	1339	1	2025-09-18	1	2500.00
2761	1340	4	2025-09-23	2	1800.00
2762	1341	5	2025-09-26	3	15000.00
2763	1341	3	2025-09-27	1	3500.00
2764	1342	7	2025-10-01	3	12000.00
2765	1342	7	2025-10-01	1	12000.00
2766	1343	3	2025-07-02	3	3500.00
2767	1344	5	2025-07-05	2	15000.00
2768	1344	6	2025-07-05	2	600.00
2769	1345	6	2025-07-12	3	600.00
2770	1345	7	2025-07-09	4	12000.00
2771	1346	6	2025-07-16	3	600.00
2772	1346	4	2025-07-14	2	1800.00
2773	1346	1	2025-07-14	3	2500.00
2774	1346	3	2025-07-15	3	3500.00
2775	1347	5	2025-07-17	4	15000.00
2776	1347	5	2025-07-17	1	15000.00
2777	1347	2	2025-07-17	3	6000.00
2778	1347	4	2025-07-17	3	1800.00
2779	1350	7	2025-07-29	2	12000.00
2780	1350	7	2025-08-01	2	12000.00
2781	1351	3	2025-08-02	2	3500.00
2782	1351	5	2025-08-02	3	15000.00
2783	1352	2	2025-08-05	3	6000.00
2784	1352	5	2025-08-05	3	15000.00
2785	1353	5	2025-08-11	3	15000.00
2786	1354	7	2025-08-14	2	12000.00
2787	1356	1	2025-08-25	1	2500.00
2788	1356	4	2025-08-23	1	1800.00
2789	1356	3	2025-08-25	3	3500.00
2790	1357	2	2025-08-27	4	6000.00
2791	1357	3	2025-08-27	3	3500.00
2792	1357	7	2025-08-27	4	12000.00
2793	1357	6	2025-08-28	2	600.00
2794	1358	6	2025-09-05	3	600.00
2795	1358	3	2025-09-04	1	3500.00
2796	1358	3	2025-09-03	3	3500.00
2797	1358	2	2025-09-04	3	6000.00
2798	1360	5	2025-09-14	4	15000.00
2799	1360	3	2025-09-15	4	3500.00
2800	1360	5	2025-09-15	1	15000.00
2801	1360	1	2025-09-15	2	2500.00
2802	1361	6	2025-09-19	3	600.00
2803	1361	1	2025-09-17	3	2500.00
2804	1361	1	2025-09-18	3	2500.00
2805	1361	5	2025-09-19	4	15000.00
2806	1362	6	2025-09-23	2	600.00
2807	1362	3	2025-09-22	4	3500.00
2808	1362	4	2025-09-23	1	1800.00
2809	1363	7	2025-09-25	4	12000.00
2810	1363	3	2025-09-28	1	3500.00
2811	1363	5	2025-09-25	3	15000.00
2812	1366	2	2025-07-06	2	6000.00
2813	1367	6	2025-07-12	2	600.00
2814	1367	7	2025-07-12	3	12000.00
2815	1367	1	2025-07-12	1	2500.00
2816	1368	5	2025-07-13	4	15000.00
2817	1368	6	2025-07-14	3	600.00
2818	1370	2	2025-07-22	4	6000.00
2819	1370	2	2025-07-24	3	6000.00
2820	1370	6	2025-07-23	2	600.00
2821	1371	5	2025-07-27	2	15000.00
2822	1372	1	2025-08-01	4	2500.00
2823	1372	3	2025-08-01	1	3500.00
2824	1372	2	2025-08-01	4	6000.00
2825	1375	4	2025-08-10	3	1800.00
2826	1376	1	2025-08-16	3	2500.00
2827	1376	4	2025-08-16	2	1800.00
2828	1376	1	2025-08-16	1	2500.00
2829	1376	6	2025-08-15	4	600.00
2830	1377	7	2025-08-20	2	12000.00
2831	1377	7	2025-08-19	3	12000.00
2832	1377	2	2025-08-19	3	6000.00
2833	1377	3	2025-08-18	3	3500.00
2834	1378	5	2025-08-22	2	15000.00
2835	1378	7	2025-08-23	3	12000.00
2836	1378	5	2025-08-24	3	15000.00
2837	1379	7	2025-08-28	4	12000.00
2838	1379	4	2025-08-27	2	1800.00
2839	1380	6	2025-09-02	2	600.00
2840	1380	6	2025-09-01	2	600.00
2841	1380	2	2025-09-02	3	6000.00
2842	1380	1	2025-09-02	3	2500.00
2843	1381	5	2025-09-09	3	15000.00
2844	1384	2	2025-09-24	4	6000.00
2845	1385	1	2025-09-27	2	2500.00
2846	1385	5	2025-09-27	1	15000.00
2847	1385	6	2025-09-27	2	600.00
2848	1386	4	2025-09-30	3	1800.00
2849	1386	7	2025-09-30	3	12000.00
2850	1386	1	2025-09-30	1	2500.00
2851	1387	4	2025-07-02	2	1800.00
2852	1387	4	2025-07-02	3	1800.00
2853	1387	3	2025-07-03	2	3500.00
2854	1387	3	2025-07-01	3	3500.00
2855	1389	1	2025-07-10	4	2500.00
2856	1389	5	2025-07-11	1	15000.00
2857	1389	3	2025-07-11	3	3500.00
2858	1391	1	2025-07-19	1	2500.00
2859	1391	6	2025-07-18	1	600.00
2860	1392	2	2025-07-24	1	6000.00
2861	1392	2	2025-07-22	2	6000.00
2862	1393	3	2025-07-30	2	3500.00
2863	1393	4	2025-07-28	1	1800.00
2864	1393	6	2025-07-28	4	600.00
2865	1395	4	2025-08-04	3	1800.00
2866	1396	6	2025-08-08	3	600.00
2867	1396	2	2025-08-07	1	6000.00
2868	1396	6	2025-08-08	4	600.00
2869	1396	1	2025-08-09	1	2500.00
2870	1397	3	2025-08-12	4	3500.00
2871	1397	2	2025-08-13	2	6000.00
2872	1397	2	2025-08-12	1	6000.00
2873	1397	1	2025-08-13	3	2500.00
2874	1398	1	2025-08-17	3	2500.00
2875	1398	7	2025-08-15	1	12000.00
2876	1398	1	2025-08-17	2	2500.00
2877	1398	3	2025-08-17	3	3500.00
2878	1399	6	2025-08-21	1	600.00
2879	1399	2	2025-08-21	1	6000.00
2880	1400	2	2025-08-24	4	6000.00
2881	1400	1	2025-08-25	3	2500.00
2882	1400	6	2025-08-25	3	600.00
2883	1400	7	2025-08-25	3	12000.00
2884	1401	4	2025-08-29	3	1800.00
2885	1401	1	2025-08-29	4	2500.00
2886	1402	4	2025-09-03	4	1800.00
2887	1402	4	2025-09-01	2	1800.00
2888	1404	2	2025-09-10	2	6000.00
2889	1404	3	2025-09-08	2	3500.00
2890	1404	3	2025-09-08	4	3500.00
2891	1405	3	2025-09-13	3	3500.00
2892	1405	6	2025-09-13	1	600.00
2893	1405	5	2025-09-13	1	15000.00
2894	1406	1	2025-09-17	2	2500.00
2895	1407	3	2025-09-21	3	3500.00
2896	1407	5	2025-09-21	1	15000.00
2897	1407	2	2025-09-21	1	6000.00
2898	1408	5	2025-09-24	2	15000.00
2899	1408	4	2025-09-24	2	1800.00
2900	1408	5	2025-09-24	4	15000.00
2901	1409	6	2025-09-28	4	600.00
2902	1409	3	2025-09-27	1	3500.00
2903	1410	2	2025-09-30	4	6000.00
2904	1441	2	2025-10-07	3	6000.00
2905	1441	2	2025-10-08	1	2500.00
2906	1441	2	2025-11-11	2	1500.00
2907	1449	1	2025-11-11	1	1500.00
2908	1449	1	2025-11-11	1	1500.00
2909	1449	1	2025-11-11	1	2500.00
\.


--
-- TOC entry 5558 (class 0 OID 17330)
-- Dependencies: 248
-- Data for Name: user_account; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_account (user_id, username, password_hash, role, guest_id) FROM stdin;
43	manager_kandy	$2a$10$dummyhash	Manager	\N
44	manager_galle	$2a$10$dummyhash	Manager	\N
46	recept_kandy	$2a$10$dummyhash	Receptionist	\N
47	recept_galle	$2a$10$dummyhash	Receptionist	\N
48	accountant_colombo	$2a$10$dummyhash	Accountant	\N
49	accountant_kandy	$2a$10$dummyhash	Accountant	\N
50	accountant_galle	$2a$10$dummyhash	Accountant	\N
42	manager_colombo	$2b$10$EP2f7QKggEk9tQDY0RbHou3Vu0GlbrKSwQfuwRXQIl5SXG4p57nVK	Manager	\N
45	recept_colombo	$2b$12$z4re42swc0WxMpL/dmCtveRDo5ew0u4Wzc3pW/oNjcJri0tJVFE8S	Receptionist	\N
6	nuwan.peiris7	$2a$12$NMfgEoqgOnvZnMynHuhDU.a5SMWu1srqU6eADOk1O5R/k0Ga.neG6	Customer	\N
41	admin	$2a$12$Z2vnNMXGUB1rPkSGz0y8gef2wexir3hsJyCAmALjY7/OYIf0DOA3.	Admin	\N
\.


--
-- TOC entry 5581 (class 0 OID 0)
-- Dependencies: 221
-- Name: audit_log_audit_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.audit_log_audit_id_seq', 101, true);


--
-- TOC entry 5582 (class 0 OID 0)
-- Dependencies: 223
-- Name: booking_booking_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.booking_booking_id_seq', 1464, true);


--
-- TOC entry 5583 (class 0 OID 0)
-- Dependencies: 225
-- Name: branch_branch_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.branch_branch_id_seq', 3, true);


--
-- TOC entry 5584 (class 0 OID 0)
-- Dependencies: 227
-- Name: customer_customer_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.customer_customer_id_seq', 25, true);


--
-- TOC entry 5585 (class 0 OID 0)
-- Dependencies: 229
-- Name: employee_employee_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.employee_employee_id_seq', 15, true);


--
-- TOC entry 5586 (class 0 OID 0)
-- Dependencies: 231
-- Name: guest_guest_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.guest_guest_id_seq', 151, true);


--
-- TOC entry 5587 (class 0 OID 0)
-- Dependencies: 233
-- Name: invoice_invoice_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.invoice_invoice_id_seq', 1, false);


--
-- TOC entry 5588 (class 0 OID 0)
-- Dependencies: 236
-- Name: payment_adjustment_adjustment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.payment_adjustment_adjustment_id_seq', 14, true);


--
-- TOC entry 5589 (class 0 OID 0)
-- Dependencies: 237
-- Name: payment_payment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.payment_payment_id_seq', 1671, true);


--
-- TOC entry 5590 (class 0 OID 0)
-- Dependencies: 239
-- Name: pre_booking_pre_booking_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pre_booking_pre_booking_id_seq', 6, true);


--
-- TOC entry 5591 (class 0 OID 0)
-- Dependencies: 241
-- Name: room_room_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.room_room_id_seq', 60, true);


--
-- TOC entry 5592 (class 0 OID 0)
-- Dependencies: 243
-- Name: room_type_room_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.room_type_room_type_id_seq', 4, true);


--
-- TOC entry 5593 (class 0 OID 0)
-- Dependencies: 245
-- Name: service_catalog_service_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.service_catalog_service_id_seq', 7, true);


--
-- TOC entry 5594 (class 0 OID 0)
-- Dependencies: 247
-- Name: service_usage_service_usage_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.service_usage_service_usage_id_seq', 2909, true);


--
-- TOC entry 5595 (class 0 OID 0)
-- Dependencies: 249
-- Name: user_account_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_account_user_id_seq', 51, true);


--
-- TOC entry 5300 (class 2606 OID 17378)
-- Name: audit_log audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (audit_id);


--
-- TOC entry 5302 (class 2606 OID 17380)
-- Name: booking booking_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.booking
    ADD CONSTRAINT booking_pkey PRIMARY KEY (booking_id);


--
-- TOC entry 5307 (class 2606 OID 17382)
-- Name: branch branch_branch_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.branch
    ADD CONSTRAINT branch_branch_name_key UNIQUE (branch_name);


--
-- TOC entry 5309 (class 2606 OID 17384)
-- Name: branch branch_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.branch
    ADD CONSTRAINT branch_pkey PRIMARY KEY (branch_id);


--
-- TOC entry 5312 (class 2606 OID 17386)
-- Name: customer customer_guest_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer
    ADD CONSTRAINT customer_guest_id_key UNIQUE (guest_id);


--
-- TOC entry 5314 (class 2606 OID 17388)
-- Name: customer customer_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer
    ADD CONSTRAINT customer_pkey PRIMARY KEY (customer_id);


--
-- TOC entry 5316 (class 2606 OID 17390)
-- Name: customer customer_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer
    ADD CONSTRAINT customer_user_id_key UNIQUE (user_id);


--
-- TOC entry 5318 (class 2606 OID 17392)
-- Name: employee employee_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_email_key UNIQUE (email);


--
-- TOC entry 5320 (class 2606 OID 17394)
-- Name: employee employee_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_pkey PRIMARY KEY (employee_id);


--
-- TOC entry 5322 (class 2606 OID 17396)
-- Name: employee employee_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_user_id_key UNIQUE (user_id);


--
-- TOC entry 5324 (class 2606 OID 17398)
-- Name: guest guest_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.guest
    ADD CONSTRAINT guest_email_key UNIQUE (email);


--
-- TOC entry 5326 (class 2606 OID 17400)
-- Name: guest guest_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.guest
    ADD CONSTRAINT guest_pkey PRIMARY KEY (guest_id);


--
-- TOC entry 5328 (class 2606 OID 17402)
-- Name: invoice invoice_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoice
    ADD CONSTRAINT invoice_pkey PRIMARY KEY (invoice_id);


--
-- TOC entry 5305 (class 2606 OID 17404)
-- Name: booking no_overlapping_bookings; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.booking
    ADD CONSTRAINT no_overlapping_bookings EXCLUDE USING gist (room_id WITH =, daterange(check_in_date, check_out_date, '[)'::text) WITH &&) WHERE ((status = ANY (ARRAY['Booked'::public.booking_status, 'Checked-In'::public.booking_status]))) DEFERRABLE;


--
-- TOC entry 5335 (class 2606 OID 17407)
-- Name: payment_adjustment payment_adjustment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment_adjustment
    ADD CONSTRAINT payment_adjustment_pkey PRIMARY KEY (adjustment_id);


--
-- TOC entry 5331 (class 2606 OID 17409)
-- Name: payment payment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_pkey PRIMARY KEY (payment_id);


--
-- TOC entry 5338 (class 2606 OID 17411)
-- Name: pre_booking pre_booking_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pre_booking
    ADD CONSTRAINT pre_booking_pkey PRIMARY KEY (pre_booking_id);


--
-- TOC entry 5340 (class 2606 OID 17413)
-- Name: room room_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.room
    ADD CONSTRAINT room_pkey PRIMARY KEY (room_id);


--
-- TOC entry 5342 (class 2606 OID 17415)
-- Name: room_type room_type_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.room_type
    ADD CONSTRAINT room_type_name_key UNIQUE (name);


--
-- TOC entry 5344 (class 2606 OID 17417)
-- Name: room_type room_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.room_type
    ADD CONSTRAINT room_type_pkey PRIMARY KEY (room_type_id);


--
-- TOC entry 5346 (class 2606 OID 17419)
-- Name: service_catalog service_catalog_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_catalog
    ADD CONSTRAINT service_catalog_code_key UNIQUE (code);


--
-- TOC entry 5348 (class 2606 OID 17421)
-- Name: service_catalog service_catalog_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_catalog
    ADD CONSTRAINT service_catalog_pkey PRIMARY KEY (service_id);


--
-- TOC entry 5350 (class 2606 OID 17423)
-- Name: service_usage service_usage_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_usage
    ADD CONSTRAINT service_usage_pkey PRIMARY KEY (service_usage_id);


--
-- TOC entry 5352 (class 2606 OID 17425)
-- Name: user_account user_account_guest_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_account
    ADD CONSTRAINT user_account_guest_id_key UNIQUE (guest_id);


--
-- TOC entry 5354 (class 2606 OID 17427)
-- Name: user_account user_account_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_account
    ADD CONSTRAINT user_account_pkey PRIMARY KEY (user_id);


--
-- TOC entry 5356 (class 2606 OID 17429)
-- Name: user_account user_account_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_account
    ADD CONSTRAINT user_account_username_key UNIQUE (username);


--
-- TOC entry 5333 (class 1259 OID 17430)
-- Name: idx_adjust_booking; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_adjust_booking ON public.payment_adjustment USING btree (booking_id);


--
-- TOC entry 5303 (class 1259 OID 17431)
-- Name: idx_booking_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_booking_created_at ON public.booking USING btree (created_at);


--
-- TOC entry 5336 (class 1259 OID 17432)
-- Name: idx_pre_booking_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pre_booking_created_at ON public.pre_booking USING btree (created_at);


--
-- TOC entry 5329 (class 1259 OID 17433)
-- Name: payment_paidat_ix; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX payment_paidat_ix ON public.payment USING btree (paid_at);


--
-- TOC entry 5332 (class 1259 OID 17434)
-- Name: uq_booking_payment_ref; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_booking_payment_ref ON public.payment USING btree (booking_id, payment_reference);


--
-- TOC entry 5310 (class 1259 OID 17435)
-- Name: uq_branch_code; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_branch_code ON public.branch USING btree (branch_code);


--
-- TOC entry 5375 (class 2620 OID 17436)
-- Name: booking booking_min_advance_guard; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER booking_min_advance_guard BEFORE INSERT OR UPDATE OF check_in_date, check_out_date, booked_rate, advance_payment ON public.booking FOR EACH ROW EXECUTE FUNCTION public.trg_check_min_advance();


--
-- TOC entry 5376 (class 2620 OID 17437)
-- Name: booking refund_advance_on_cancel; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER refund_advance_on_cancel AFTER UPDATE OF status ON public.booking FOR EACH ROW EXECUTE FUNCTION public.trg_refund_advance_on_cancel();


--
-- TOC entry 5377 (class 2620 OID 17438)
-- Name: booking refund_advance_policy; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER refund_advance_policy AFTER UPDATE OF status ON public.booking FOR EACH ROW EXECUTE FUNCTION public.trg_refund_advance_policy();


--
-- TOC entry 5357 (class 2606 OID 17439)
-- Name: booking fk_book_guest; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.booking
    ADD CONSTRAINT fk_book_guest FOREIGN KEY (guest_id) REFERENCES public.guest(guest_id);


--
-- TOC entry 5358 (class 2606 OID 17444)
-- Name: booking fk_book_pre; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.booking
    ADD CONSTRAINT fk_book_pre FOREIGN KEY (pre_booking_id) REFERENCES public.pre_booking(pre_booking_id);


--
-- TOC entry 5359 (class 2606 OID 17449)
-- Name: booking fk_book_room; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.booking
    ADD CONSTRAINT fk_book_room FOREIGN KEY (room_id) REFERENCES public.room(room_id);


--
-- TOC entry 5360 (class 2606 OID 17454)
-- Name: customer fk_cust_guest; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer
    ADD CONSTRAINT fk_cust_guest FOREIGN KEY (guest_id) REFERENCES public.guest(guest_id);


--
-- TOC entry 5361 (class 2606 OID 17459)
-- Name: customer fk_cust_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer
    ADD CONSTRAINT fk_cust_user FOREIGN KEY (user_id) REFERENCES public.user_account(user_id);


--
-- TOC entry 5362 (class 2606 OID 17464)
-- Name: employee fk_emp_branch; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT fk_emp_branch FOREIGN KEY (branch_id) REFERENCES public.branch(branch_id);


--
-- TOC entry 5363 (class 2606 OID 17469)
-- Name: employee fk_emp_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT fk_emp_user FOREIGN KEY (user_id) REFERENCES public.user_account(user_id);


--
-- TOC entry 5364 (class 2606 OID 17474)
-- Name: invoice fk_inv_book; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoice
    ADD CONSTRAINT fk_inv_book FOREIGN KEY (booking_id) REFERENCES public.booking(booking_id);


--
-- TOC entry 5365 (class 2606 OID 17479)
-- Name: payment fk_pay_book; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT fk_pay_book FOREIGN KEY (booking_id) REFERENCES public.booking(booking_id);


--
-- TOC entry 5367 (class 2606 OID 17484)
-- Name: pre_booking fk_pre_creator; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pre_booking
    ADD CONSTRAINT fk_pre_creator FOREIGN KEY (created_by_employee_id) REFERENCES public.employee(employee_id);


--
-- TOC entry 5368 (class 2606 OID 17489)
-- Name: pre_booking fk_pre_guest; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pre_booking
    ADD CONSTRAINT fk_pre_guest FOREIGN KEY (guest_id) REFERENCES public.guest(guest_id);


--
-- TOC entry 5369 (class 2606 OID 17494)
-- Name: pre_booking fk_pre_room; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pre_booking
    ADD CONSTRAINT fk_pre_room FOREIGN KEY (room_id) REFERENCES public.room(room_id);


--
-- TOC entry 5370 (class 2606 OID 17499)
-- Name: room fk_room_branch; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.room
    ADD CONSTRAINT fk_room_branch FOREIGN KEY (branch_id) REFERENCES public.branch(branch_id);


--
-- TOC entry 5371 (class 2606 OID 17504)
-- Name: room fk_room_type; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.room
    ADD CONSTRAINT fk_room_type FOREIGN KEY (room_type_id) REFERENCES public.room_type(room_type_id);


--
-- TOC entry 5372 (class 2606 OID 17509)
-- Name: service_usage fk_usage_book; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_usage
    ADD CONSTRAINT fk_usage_book FOREIGN KEY (booking_id) REFERENCES public.booking(booking_id);


--
-- TOC entry 5373 (class 2606 OID 17514)
-- Name: service_usage fk_usage_serv; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_usage
    ADD CONSTRAINT fk_usage_serv FOREIGN KEY (service_id) REFERENCES public.service_catalog(service_id);


--
-- TOC entry 5374 (class 2606 OID 17519)
-- Name: user_account fk_user_guest; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_account
    ADD CONSTRAINT fk_user_guest FOREIGN KEY (guest_id) REFERENCES public.guest(guest_id);


--
-- TOC entry 5366 (class 2606 OID 17524)
-- Name: payment_adjustment payment_adjustment_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment_adjustment
    ADD CONSTRAINT payment_adjustment_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.booking(booking_id) ON DELETE CASCADE;


-- Completed on 2025-10-18 02:49:51

--
-- PostgreSQL database dump complete
--

\unrestrict Qy1DrmI3OE1bo6KS02qsf7FF3YtkAjj6SCuoRvfiFOPZz61Pezqs6hYYXfPCJh6

