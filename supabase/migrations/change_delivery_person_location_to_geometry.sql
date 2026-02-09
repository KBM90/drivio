-- Change delivery_persons.current_location from geography to geometry
-- This makes it consistent with drivers.location which uses geometry

ALTER TABLE delivery_persons 
ALTER COLUMN current_location TYPE geometry(Point, 4326) 
USING current_location::geometry;
