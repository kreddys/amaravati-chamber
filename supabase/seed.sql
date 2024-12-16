SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE SCHEMA IF NOT EXISTS "amaravati-chamber";


ALTER SCHEMA "amaravati-chamber" OWNER TO "postgres";


CREATE SCHEMA IF NOT EXISTS "data";


ALTER SCHEMA "data" OWNER TO "postgres";


CREATE SCHEMA IF NOT EXISTS "gis";


ALTER SCHEMA "gis" OWNER TO "postgres";


CREATE EXTENSION IF NOT EXISTS "pgsodium" WITH SCHEMA "pgsodium";






COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "postgis" WITH SCHEMA "gis";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE TYPE "public"."approval_status" AS ENUM (
    'pending',
    'approved',
    'rejected'
);


ALTER TYPE "public"."approval_status" OWNER TO "postgres";


CREATE TYPE "public"."business_status" AS ENUM (
    'pending',
    'approved',
    'rejected'
);


ALTER TYPE "public"."business_status" OWNER TO "postgres";


CREATE TYPE "public"."entity_type" AS ENUM (
    'article',
    'comment',
    'event',
    'place'
);


ALTER TYPE "public"."entity_type" OWNER TO "postgres";


CREATE TYPE "public"."user_role" AS ENUM (
    'user',
    'admin',
    'moderator'
);


ALTER TYPE "public"."user_role" OWNER TO "postgres";


CREATE TYPE "public"."vote_type" AS ENUM (
    'upvote',
    'downvote'
);


ALTER TYPE "public"."vote_type" OWNER TO "postgres";

CREATE OR REPLACE FUNCTION get_places_by_category(
    category_filter text,
    page_number integer DEFAULT 1,
    entries_per_page integer DEFAULT 10
) 
RETURNS TABLE (
    uuid uuid,
    name text,
    address text,
    category text,
    description text,
    contact_number varchar,
    website varchar,
    social varchar,
    latitude double precision,
    longitude double precision,
    images jsonb,
    upvotes bigint,
    downvotes bigint,
    user_vote text,
    total_count bigint
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    WITH vote_counts AS (
        SELECT 
            entity_id,
            COUNT(CASE WHEN vote_type = 'upvote' THEN 1 END) as upvote_count,
            COUNT(CASE WHEN vote_type = 'downvote' THEN 1 END) as downvote_count
        FROM votes
        WHERE entity_type = 'place'
        GROUP BY entity_id
    ),
    user_votes AS (
        SELECT 
            entity_id,
            vote_type
        FROM votes
        WHERE entity_type = 'place'
        AND user_id = auth.uid()
    ),
    approved_places AS (
        SELECT 
            p.uuid,
            CASE 
                WHEN p.names IS NOT NULL AND p.names->>'primary' IS NOT NULL
                THEN p.names->>'primary'
                ELSE NULL 
            END as name,
            CASE 
                WHEN p.addresses IS NOT NULL AND jsonb_array_length(p.addresses::jsonb) > 0 
                THEN (
                    SELECT concat_ws(', ', 
                        a->>'freeform',
                        NULLIF(a->>'locality', ''),
                        NULLIF(a->>'postcode', ''),
                        NULLIF(a->>'country', '')
                    )
                    FROM jsonb_array_elements(p.addresses::jsonb) a
                    LIMIT 1
                )
                ELSE NULL 
            END as address,
            CASE 
                WHEN p.categories IS NOT NULL AND p.categories->>'primary' IS NOT NULL
                THEN p.categories->>'primary'
                ELSE NULL 
            END as category,
            NULL as description,
            CASE 
                WHEN p.phones IS NOT NULL AND array_length(p.phones, 1) > 0 
                THEN p.phones[1]
                ELSE NULL 
            END as contact_number,
            CASE 
                WHEN p.websites IS NOT NULL AND array_length(p.websites, 1) > 0 
                THEN p.websites[1]
                ELSE NULL 
            END as website,
            CASE 
                WHEN p.socials IS NOT NULL AND array_length(p.socials, 1) > 0 
                THEN p.socials[1]
                ELSE NULL 
            END as social,
            gis.ST_Y(wkb_geometry::gis.geometry) as latitude,
            gis.ST_X(wkb_geometry::gis.geometry) as longitude,
            NULL::jsonb as images,
            COUNT(*) OVER() as total_count
        FROM amaravati_places p
        WHERE EXISTS (
            SELECT 1 
            FROM approvals a 
            WHERE a.entity_id = p.uuid 
            AND a.status = 'approved'
            AND a.entity_type = 'place'
        )
        AND (
            category_filter = 'All' 
            OR (
                p.categories IS NOT NULL 
                AND p.categories->>'primary' = category_filter
            )
        )
    )
    SELECT 
        ap.uuid,
        ap.name,
        ap.address,
        ap.category,
        ap.description,
        ap.contact_number,
        ap.website,
        ap.social,
        ap.latitude,
        ap.longitude,
        ap.images,
        COALESCE(vc.upvote_count, 0) as upvotes,
        COALESCE(vc.downvote_count, 0) as downvotes,
        uv.vote_type::text as user_vote,
        ap.total_count
    FROM approved_places ap
    LEFT JOIN vote_counts vc ON ap.uuid = vc.entity_id
    LEFT JOIN user_votes uv ON ap.uuid = uv.entity_id
    ORDER BY ap.name
    LIMIT entries_per_page
    OFFSET ((page_number - 1) * entries_per_page);
END;
$$;

CREATE OR REPLACE FUNCTION get_approved_place_categories()
RETURNS TABLE (category text, count bigint) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
    WITH approved_places AS (
      SELECT p.*
      FROM amaravati_places p
      WHERE EXISTS (
        SELECT 1 
        FROM approvals a 
        WHERE a.entity_id = p.uuid 
        AND a.status = 'approved'
        AND a.entity_type = 'place'
      )
    )
    SELECT 
      CASE 
        WHEN p.categories IS NOT NULL AND p.categories->>'primary' IS NOT NULL
        THEN p.categories->>'primary'
        ELSE 'Uncategorized'
      END as category_name,
      COUNT(*) as category_count
    FROM approved_places p
    GROUP BY 
      CASE 
        WHEN p.categories IS NOT NULL AND p.categories->>'primary' IS NOT NULL
        THEN p.categories->>'primary'
        ELSE 'Uncategorized'
      END
    HAVING 
      CASE 
        WHEN p.categories IS NOT NULL AND p.categories->>'primary' IS NOT NULL
        THEN p.categories->>'primary'
        ELSE 'Uncategorized'
      END IS NOT NULL
    ORDER BY category_count DESC, category_name ASC;
END;
$$;


CREATE OR REPLACE FUNCTION "public"."calculate_distances"("target_lon" double precision, "target_lat" double precision) RETURNS TABLE("id" character varying, "names" "json", "addresses" "json", "phones" character varying[], "websites" character varying[], "distance" double precision)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.names,
        p.addresses,
        p.phones,
        p.websites,
        gis.ST_Distance(
            p.wkb_geometry::gis.geography,
            gis.ST_SetSRID(gis.ST_MakePoint(target_lon, target_lat), 4326)::gis.geography
        ) AS distance
    FROM amaravati_places p
    JOIN business_approvals ba ON p.id = ba.business_id
    WHERE p.wkb_geometry IS NOT NULL
    AND ba.status = 'approved'
    ORDER BY distance ASC;
END;
$$;


ALTER FUNCTION "public"."calculate_distances"("target_lon" double precision, "target_lat" double precision) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_approved_places_with_votes"("page_number" integer DEFAULT 1, "entries_per_page" integer DEFAULT 10) RETURNS TABLE("uuid" "uuid", "name" "text", "address" "text", "category" "text", "description" "text", "contact_number" character varying, "website" character varying, "social" character varying, "latitude" double precision, "longitude" double precision, "images" "jsonb", "upvotes" bigint, "downvotes" bigint, "user_vote" "text", "total_count" bigint)
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  -- Add input validation
  if page_number < 1 then
    page_number := 1;
  end if;
  
  if entries_per_page < 1 then
    entries_per_page := 10; -- default to 10 if invalid
  end if;
    RETURN QUERY
    WITH vote_counts AS (
        SELECT 
            entity_id,
            COUNT(CASE WHEN vote_type = 'upvote' THEN 1 END) as upvote_count,
            COUNT(CASE WHEN vote_type = 'downvote' THEN 1 END) as downvote_count
        FROM votes
        WHERE entity_type = 'place'
        GROUP BY entity_id
    ),
    user_votes AS (
        SELECT 
            entity_id,
            vote_type
        FROM votes
        WHERE entity_type = 'place'
        AND user_id = auth.uid()
    ),
    approved_places AS (
        SELECT 
            p.uuid,
            CASE 
                WHEN p.names IS NOT NULL AND p.names->>'primary' IS NOT NULL
                THEN p.names->>'primary'
                ELSE NULL 
            END as name,
            CASE 
                WHEN p.addresses IS NOT NULL AND jsonb_array_length(p.addresses::jsonb) > 0 
                THEN (
                    SELECT concat_ws(', ', 
                        a->>'freeform',
                        NULLIF(a->>'locality', ''),
                        NULLIF(a->>'postcode', ''),
                        NULLIF(a->>'country', '')
                    )
                    FROM jsonb_array_elements(p.addresses::jsonb) a
                    LIMIT 1
                )
                ELSE NULL 
            END as address,
            CASE 
                WHEN p.categories IS NOT NULL AND p.categories->>'primary' IS NOT NULL
                THEN p.categories->>'primary'
                ELSE NULL 
            END as category,
            NULL as description,
            CASE 
                WHEN p.phones IS NOT NULL AND array_length(p.phones, 1) > 0 
                THEN p.phones[1]
                ELSE NULL 
            END as contact_number,
            CASE 
                WHEN p.websites IS NOT NULL AND array_length(p.websites, 1) > 0 
                THEN p.websites[1]
                ELSE NULL 
            END as website,
            CASE 
                WHEN p.socials IS NOT NULL AND array_length(p.socials, 1) > 0 
                THEN p.socials[1]
                ELSE NULL 
            END as social,
            gis.ST_Y(wkb_geometry::gis.geometry) as latitude,
            gis.ST_X(wkb_geometry::gis.geometry) as longitude,
            NULL::jsonb as images,
            COUNT(*) OVER() as total_count
        FROM amaravati_places p
        WHERE EXISTS (
            SELECT 1 
            FROM approvals a 
            WHERE a.entity_id = p.uuid 
            AND a.status = 'approved'
            AND a.entity_type = 'place'
        )
    )
    SELECT 
        ap.uuid,
        ap.name,
        ap.address,
        ap.category,
        ap.description,
        ap.contact_number,
        ap.website,
        ap.social,
        ap.latitude,
        ap.longitude,
        ap.images,
        COALESCE(vc.upvote_count, 0) as upvotes,
        COALESCE(vc.downvote_count, 0) as downvotes,
        uv.vote_type::text as user_vote,
        ap.total_count
    FROM approved_places ap
    LEFT JOIN vote_counts vc ON ap.uuid = vc.entity_id
    LEFT JOIN user_votes uv ON ap.uuid = uv.entity_id
    ORDER BY ap.name
    LIMIT entries_per_page
    OFFSET ((page_number - 1) * entries_per_page);
END;
$$;


ALTER FUNCTION "public"."get_approved_places_with_votes"("page_number" integer, "entries_per_page" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_admin"() RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM user_roles 
        WHERE user_id = auth.uid() 
        AND role = 'admin'
    );
END;
$$;


ALTER FUNCTION "public"."is_admin"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."mvt"("relation" "text", "z" integer, "x" integer, "y" integer) RETURNS "text"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    mvt_output text;
BEGIN
    WITH 
    -- Define the bounds of the tile using the provided Z, X, Y coordinates
    bounds AS (
        SELECT gis.ST_TileEnvelope(z, x, y) AS geom
    ),
    -- Transform the geometries from EPSG:4326 to EPSG:3857 and clip them to the tile bounds
    mvtgeom AS (
        SELECT 
            -- include the name and id only at zoom 13 to make low-zoom tiles smaller
            CASE 
            WHEN z > 13 THEN id
            ELSE NULL
            END AS id,
            CASE 
            WHEN z > 13 THEN names::json->>'primary'
            ELSE NULL
            END AS primary_name,
            categories::json->>'main' as main_category,
            gis.ST_AsMVTGeom(
                gis.ST_Transform(wkb_geometry, 3857), -- Transform the geometry to Web Mercator
                bounds.geom,
                4096, -- The extent of the tile in pixels (commonly 256 or 4096)
                0,    -- Buffer around the tile in pixels
                true  -- Clip geometries to the tile extent
            ) AS geom
        FROM 
            amaravati_places, bounds
        WHERE 
            gis.ST_Intersects(gis.ST_Transform(wkb_geometry, 3857), bounds.geom)
    )
    -- Generate the MVT from the clipped geometries
    SELECT INTO mvt_output encode(gis.ST_AsMVT(mvtgeom, relation, 4096, 'geom'),'base64')
    FROM mvtgeom;

    RETURN mvt_output;
END;
$$;


ALTER FUNCTION "public"."mvt"("relation" "text", "z" integer, "x" integer, "y" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."search_places"("search_query" "text") RETURNS TABLE("ogc_fid" integer, "wkb_geometry" "gis"."geometry", "id" character varying, "version" integer, "sources" "json", "names" "json", "categories" "json", "confidence" double precision, "websites" character varying[], "socials" character varying[], "phones" character varying[], "brand" "json", "addresses" "json", "upvotes" bigint, "downvotes" bigint, "user_vote" integer)
    LANGUAGE "plpgsql"
    AS $$
begin
  return query
    WITH vote_counts AS (
        SELECT 
            entity_id::varchar as entity_id,  -- Cast UUID to varchar
            COUNT(CASE WHEN vote_type = 'upvote' THEN 1 END) as upvote_count,
            COUNT(CASE WHEN vote_type = 'downvote' THEN 1 END) as downvote_count
        FROM votes
        WHERE entity_type = 'place'
        GROUP BY entity_id
    ),
    user_votes AS (
        SELECT 
            entity_id::varchar as entity_id,  -- Cast UUID to varchar
            vote_type
        FROM votes
        WHERE entity_type = 'place'
        AND user_id = auth.uid()
    ),
    approved_places AS (
        SELECT 
            p.ogc_fid,
            p.wkb_geometry,
            p.id,
            p.version,
            p.sources,
            p.names,
            p.categories,
            p.confidence,
            p.websites,
            p.socials,
            p.phones,
            p.brand,
            p.addresses,
            CASE 
                WHEN p.names IS NOT NULL AND p.names->>'default' IS NOT NULL
                THEN p.names->>'default'
                ELSE NULL 
            END as name,
            CASE 
                WHEN p.addresses IS NOT NULL AND jsonb_typeof(p.addresses::jsonb) = 'array' AND jsonb_array_length(p.addresses::jsonb) > 0 
                THEN (
                    SELECT concat_ws(', ', 
                        a->>'freeform',
                        NULLIF(a->>'locality', ''),
                        NULLIF(a->>'postcode', ''),
                        NULLIF(a->>'country', '')
                    )
                    FROM jsonb_array_elements(p.addresses::jsonb) a
                    LIMIT 1
                )
                ELSE NULL 
            END as address,
            CASE 
                WHEN p.categories IS NOT NULL AND jsonb_typeof(p.categories::jsonb) = 'object' AND p.categories->>'primary' IS NOT NULL
                THEN p.categories->>'primary'
                ELSE NULL 
            END as category,
            COUNT(*) OVER() as total_count
        FROM amaravati_places p
        WHERE EXISTS (
            SELECT 1 
            FROM approvals a 
            WHERE a.entity_id::varchar = p.uuid::varchar  -- Cast both to varchar for comparison
            AND a.status = 'approved'
            AND a.entity_type = 'place'
        )
        AND (
            p.names->>'primary' ILIKE '%' || search_query || '%'
            OR EXISTS (
            SELECT 1
            FROM jsonb_array_elements(p.addresses::jsonb) addr
            WHERE 
                addr->>'freeform' ILIKE '%' || search_query || '%'
                OR addr->>'locality' ILIKE '%' || search_query || '%'
                OR addr->>'postcode' ILIKE '%' || search_query || '%'
                OR addr->>'country' ILIKE '%' || search_query || '%'
        )
        OR p.categories->>'primary' ILIKE '%' || search_query || '%'
        

        )
    )
    SELECT 
        ap.ogc_fid,
        ap.wkb_geometry,
        ap.id,
        ap.version,
        ap.sources,
        ap.names,
        ap.categories,
        ap.confidence,
        ap.websites,
        ap.socials,
        ap.phones,
        ap.brand,
        ap.addresses,
        COALESCE(vc.upvote_count, 0) as upvotes,
        COALESCE(vc.downvote_count, 0) as downvotes,
        CASE 
            WHEN uv.vote_type = 'upvote' THEN 1
            WHEN uv.vote_type = 'downvote' THEN -1
            ELSE 0
        END as user_vote
    FROM approved_places ap
    LEFT JOIN vote_counts vc ON ap.id = vc.entity_id
    LEFT JOIN user_votes uv ON ap.id = uv.entity_id
    ORDER BY ap.name
    LIMIT 10;
end;
$$;


ALTER FUNCTION "public"."search_places"("search_query" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_updated_at_column"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_updated_at_column"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."validate_vote_reference"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    IF NEW.entity_type = 'article' THEN
        IF NOT EXISTS (SELECT 1 FROM articles WHERE id = NEW.entity_id) THEN
            RAISE EXCEPTION 'Invalid article reference';
        END IF;
    ELSIF NEW.entity_type = 'place' THEN
        IF NOT EXISTS (SELECT 1 FROM amaravati_places WHERE uuid = NEW.entity_id) THEN
            RAISE EXCEPTION 'Invalid place reference';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."validate_vote_reference"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."amaravati_infrastructure" (
    "ogc_fid" integer NOT NULL,
    "wkb_geometry" "gis"."geometry"(Geometry,4326),
    "id" character varying,
    "version" integer,
    "sources" "json",
    "subtype" character varying,
    "class" character varying,
    "height" double precision,
    "surface" character varying,
    "names" "json",
    "level" integer,
    "source_tags" "json",
    "wikidata" character varying
);


ALTER TABLE "public"."amaravati_infrastructure" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."amaravati_infrastructure_ogc_fid_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "public"."amaravati_infrastructure_ogc_fid_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."amaravati_infrastructure_ogc_fid_seq" OWNED BY "public"."amaravati_infrastructure"."ogc_fid";



CREATE TABLE IF NOT EXISTS "public"."amaravati_places" (
    "ogc_fid" integer NOT NULL,
    "wkb_geometry" "gis"."geometry"(Point,4326),
    "id" character varying,
    "version" integer,
    "sources" "json",
    "names" "json",
    "categories" "json",
    "confidence" double precision,
    "websites" character varying[],
    "socials" character varying[],
    "phones" character varying[],
    "brand" "json",
    "addresses" "json",
    "uuid" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL
);


ALTER TABLE "public"."amaravati_places" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."amaravati_places_ogc_fid_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "public"."amaravati_places_ogc_fid_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."amaravati_places_ogc_fid_seq" OWNED BY "public"."amaravati_places"."ogc_fid";



CREATE TABLE IF NOT EXISTS "public"."approvals" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "entity_id" "uuid" NOT NULL,
    "entity_type" "text" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "approved_by" "uuid",
    "approval_date" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT "valid_status" CHECK (("status" = ANY (ARRAY['pending'::"text", 'approved'::"text", 'rejected'::"text"])))
);


ALTER TABLE "public"."approvals" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."article_authors" (
    "article_id" "uuid" NOT NULL,
    "author_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."article_authors" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."article_tags" (
    "article_id" "uuid" NOT NULL,
    "tag_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."article_tags" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."articles" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "ghost_id" "text" NOT NULL,
    "title" "text" NOT NULL,
    "description" "text",
    "html_content" "text" NOT NULL,
    "published_at" timestamp with time zone,
    "image_url" "text",
    "slug" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."articles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."authors" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "ghost_id" "text" NOT NULL,
    "name" "text" NOT NULL,
    "slug" "text" NOT NULL,
    "email" "text",
    "profile_image" "text",
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."authors" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."geojson_polygons" (
    "id" integer NOT NULL,
    "name" character varying NOT NULL,
    "geom" "gis"."geometry"(Polygon,4326) NOT NULL
);


ALTER TABLE "public"."geojson_polygons" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."geojson_polygons_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "public"."geojson_polygons_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."geojson_polygons_id_seq" OWNED BY "public"."geojson_polygons"."id";



CREATE TABLE IF NOT EXISTS "public"."tags" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "ghost_id" "text" NOT NULL,
    "name" "text" NOT NULL,
    "slug" "text" NOT NULL,
    "description" "text",
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."tags" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_roles" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "role" "public"."user_role" DEFAULT 'user'::"public"."user_role" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL
);


ALTER TABLE "public"."user_roles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."votes" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "entity_type" "public"."entity_type" NOT NULL,
    "entity_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "vote_type" "public"."vote_type" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL
);


ALTER TABLE "public"."votes" OWNER TO "postgres";


ALTER TABLE ONLY "public"."amaravati_infrastructure" ALTER COLUMN "ogc_fid" SET DEFAULT "nextval"('"public"."amaravati_infrastructure_ogc_fid_seq"'::"regclass");



ALTER TABLE ONLY "public"."amaravati_places" ALTER COLUMN "ogc_fid" SET DEFAULT "nextval"('"public"."amaravati_places_ogc_fid_seq"'::"regclass");



ALTER TABLE ONLY "public"."geojson_polygons" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."geojson_polygons_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."amaravati_infrastructure"
    ADD CONSTRAINT "amaravati_infrastructure_pk" PRIMARY KEY ("ogc_fid");



ALTER TABLE ONLY "public"."amaravati_places"
    ADD CONSTRAINT "amaravati_places_pk" PRIMARY KEY ("ogc_fid");



ALTER TABLE ONLY "public"."amaravati_places"
    ADD CONSTRAINT "amaravati_places_uuid_key" UNIQUE ("uuid");



ALTER TABLE ONLY "public"."approvals"
    ADD CONSTRAINT "approvals_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."article_authors"
    ADD CONSTRAINT "article_authors_pkey" PRIMARY KEY ("article_id", "author_id");



ALTER TABLE ONLY "public"."article_tags"
    ADD CONSTRAINT "article_tags_pkey" PRIMARY KEY ("article_id", "tag_id");



ALTER TABLE ONLY "public"."articles"
    ADD CONSTRAINT "articles_ghost_id_key" UNIQUE ("ghost_id");



ALTER TABLE ONLY "public"."articles"
    ADD CONSTRAINT "articles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."authors"
    ADD CONSTRAINT "authors_ghost_id_key" UNIQUE ("ghost_id");



ALTER TABLE ONLY "public"."authors"
    ADD CONSTRAINT "authors_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."geojson_polygons"
    ADD CONSTRAINT "geojson_polygons_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."tags"
    ADD CONSTRAINT "tags_ghost_id_key" UNIQUE ("ghost_id");



ALTER TABLE ONLY "public"."tags"
    ADD CONSTRAINT "tags_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."approvals"
    ADD CONSTRAINT "unique_entity_approval" UNIQUE ("entity_id", "entity_type");



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_user_id_role_key" UNIQUE ("user_id", "role");



ALTER TABLE ONLY "public"."votes"
    ADD CONSTRAINT "votes_entity_type_entity_id_user_id_key" UNIQUE ("entity_type", "entity_id", "user_id");



ALTER TABLE ONLY "public"."votes"
    ADD CONSTRAINT "votes_pkey" PRIMARY KEY ("id");



CREATE INDEX "amaravati_infrastructure_wkb_geometry_geom_idx" ON "public"."amaravati_infrastructure" USING "gist" ("wkb_geometry");



CREATE INDEX "amaravati_places_wkb_geometry_geom_idx" ON "public"."amaravati_places" USING "gist" ("wkb_geometry");



CREATE INDEX "idx_approvals_entity" ON "public"."approvals" USING "btree" ("entity_id", "entity_type");



CREATE INDEX "idx_approvals_status" ON "public"."approvals" USING "btree" ("status");



CREATE INDEX "idx_articles_ghost_id" ON "public"."articles" USING "btree" ("ghost_id");



CREATE INDEX "idx_articles_slug" ON "public"."articles" USING "btree" ("slug");



CREATE INDEX "idx_authors_ghost_id" ON "public"."authors" USING "btree" ("ghost_id");



CREATE INDEX "idx_tags_ghost_id" ON "public"."tags" USING "btree" ("ghost_id");



CREATE INDEX "idx_votes_entity" ON "public"."votes" USING "btree" ("entity_type", "entity_id");



CREATE INDEX "idx_votes_user" ON "public"."votes" USING "btree" ("user_id");



CREATE INDEX "user_roles_user_id_idx" ON "public"."user_roles" USING "btree" ("user_id");



CREATE OR REPLACE TRIGGER "update_approvals_updated_at" BEFORE UPDATE ON "public"."approvals" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_article_authors_updated_at" BEFORE UPDATE ON "public"."article_authors" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_article_tags_updated_at" BEFORE UPDATE ON "public"."article_tags" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_articles_updated_at" BEFORE UPDATE ON "public"."articles" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_authors_updated_at" BEFORE UPDATE ON "public"."authors" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_tags_updated_at" BEFORE UPDATE ON "public"."tags" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_user_roles_updated_at" BEFORE UPDATE ON "public"."user_roles" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_votes_updated_at" BEFORE UPDATE ON "public"."votes" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "validate_vote_reference" BEFORE INSERT OR UPDATE ON "public"."votes" FOR EACH ROW EXECUTE FUNCTION "public"."validate_vote_reference"();



ALTER TABLE ONLY "public"."approvals"
    ADD CONSTRAINT "approvals_approved_by_fkey" FOREIGN KEY ("approved_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."article_authors"
    ADD CONSTRAINT "article_authors_article_id_fkey" FOREIGN KEY ("article_id") REFERENCES "public"."articles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."article_authors"
    ADD CONSTRAINT "article_authors_author_id_fkey" FOREIGN KEY ("author_id") REFERENCES "public"."authors"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."article_tags"
    ADD CONSTRAINT "article_tags_article_id_fkey" FOREIGN KEY ("article_id") REFERENCES "public"."articles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."article_tags"
    ADD CONSTRAINT "article_tags_tag_id_fkey" FOREIGN KEY ("tag_id") REFERENCES "public"."tags"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."votes"
    ADD CONSTRAINT "votes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



CREATE POLICY "Admins can manage approvals" ON "public"."approvals" USING ("public"."is_admin"());



CREATE POLICY "Admins can manage roles" ON "public"."user_roles" USING ("public"."is_admin"());



CREATE POLICY "Anyone can view approved entities" ON "public"."approvals" FOR SELECT USING (("status" = 'approved'::"text"));



CREATE POLICY "Anyone can view votes" ON "public"."votes" FOR SELECT USING (true);



CREATE POLICY "Public read access for article_authors" ON "public"."article_authors" FOR SELECT USING (true);



CREATE POLICY "Public read access for article_tags" ON "public"."article_tags" FOR SELECT USING (true);



CREATE POLICY "Public read access for articles" ON "public"."articles" FOR SELECT USING (true);



CREATE POLICY "Public read access for authors" ON "public"."authors" FOR SELECT USING (true);



CREATE POLICY "Public read access for tags" ON "public"."tags" FOR SELECT USING (true);



CREATE POLICY "Users can manage their own votes" ON "public"."votes" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can view their own roles" ON "public"."user_roles" FOR SELECT USING (("auth"."uid"() = "user_id"));



ALTER TABLE "public"."approvals" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."article_authors" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."article_tags" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."articles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."authors" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."tags" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_roles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."votes" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "gis" TO "anon";
GRANT USAGE ON SCHEMA "gis" TO "authenticated";



GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

GRANT ALL ON FUNCTION "public"."calculate_distances"("target_lon" double precision, "target_lat" double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."calculate_distances"("target_lon" double precision, "target_lat" double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."calculate_distances"("target_lon" double precision, "target_lat" double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_approved_places_with_votes"("page_number" integer, "entries_per_page" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_approved_places_with_votes"("page_number" integer, "entries_per_page" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_approved_places_with_votes"("page_number" integer, "entries_per_page" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."is_admin"() TO "anon";
GRANT ALL ON FUNCTION "public"."is_admin"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_admin"() TO "service_role";



GRANT ALL ON FUNCTION "public"."mvt"("relation" "text", "z" integer, "x" integer, "y" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."mvt"("relation" "text", "z" integer, "x" integer, "y" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."mvt"("relation" "text", "z" integer, "x" integer, "y" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."search_places"("search_query" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."search_places"("search_query" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."search_places"("search_query" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "service_role";



GRANT ALL ON FUNCTION "public"."validate_vote_reference"() TO "anon";
GRANT ALL ON FUNCTION "public"."validate_vote_reference"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."validate_vote_reference"() TO "service_role";


GRANT ALL ON TABLE "public"."amaravati_infrastructure" TO "anon";
GRANT ALL ON TABLE "public"."amaravati_infrastructure" TO "authenticated";
GRANT ALL ON TABLE "public"."amaravati_infrastructure" TO "service_role";



GRANT ALL ON SEQUENCE "public"."amaravati_infrastructure_ogc_fid_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."amaravati_infrastructure_ogc_fid_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."amaravati_infrastructure_ogc_fid_seq" TO "service_role";



GRANT ALL ON TABLE "public"."amaravati_places" TO "anon";
GRANT ALL ON TABLE "public"."amaravati_places" TO "authenticated";
GRANT ALL ON TABLE "public"."amaravati_places" TO "service_role";



GRANT ALL ON SEQUENCE "public"."amaravati_places_ogc_fid_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."amaravati_places_ogc_fid_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."amaravati_places_ogc_fid_seq" TO "service_role";



GRANT ALL ON TABLE "public"."approvals" TO "anon";
GRANT ALL ON TABLE "public"."approvals" TO "authenticated";
GRANT ALL ON TABLE "public"."approvals" TO "service_role";



GRANT ALL ON TABLE "public"."article_authors" TO "anon";
GRANT ALL ON TABLE "public"."article_authors" TO "authenticated";
GRANT ALL ON TABLE "public"."article_authors" TO "service_role";



GRANT ALL ON TABLE "public"."article_tags" TO "anon";
GRANT ALL ON TABLE "public"."article_tags" TO "authenticated";
GRANT ALL ON TABLE "public"."article_tags" TO "service_role";



GRANT ALL ON TABLE "public"."articles" TO "anon";
GRANT ALL ON TABLE "public"."articles" TO "authenticated";
GRANT ALL ON TABLE "public"."articles" TO "service_role";



GRANT ALL ON TABLE "public"."authors" TO "anon";
GRANT ALL ON TABLE "public"."authors" TO "authenticated";
GRANT ALL ON TABLE "public"."authors" TO "service_role";



GRANT ALL ON TABLE "public"."geojson_polygons" TO "anon";
GRANT ALL ON TABLE "public"."geojson_polygons" TO "authenticated";
GRANT ALL ON TABLE "public"."geojson_polygons" TO "service_role";



GRANT ALL ON SEQUENCE "public"."geojson_polygons_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."geojson_polygons_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."geojson_polygons_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."tags" TO "anon";
GRANT ALL ON TABLE "public"."tags" TO "authenticated";
GRANT ALL ON TABLE "public"."tags" TO "service_role";



GRANT ALL ON TABLE "public"."user_roles" TO "anon";
GRANT ALL ON TABLE "public"."user_roles" TO "authenticated";
GRANT ALL ON TABLE "public"."user_roles" TO "service_role";



GRANT ALL ON TABLE "public"."votes" TO "anon";
GRANT ALL ON TABLE "public"."votes" TO "authenticated";
GRANT ALL ON TABLE "public"."votes" TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "service_role";

RESET ALL;
