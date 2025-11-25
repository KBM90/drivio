
begin
  delete from auth.users
  where id = auth.uid();
end;
