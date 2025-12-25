-- Add description column to badges if it doesn't exist
alter table badges add column if not exists description text;

-- Insert sample badges if table is empty (Optional)
insert into badges (name, icon, xp_required, description)
select 'مستكشف كارتازيا', 'explore', 100, 'أهلاً بك في عالم كارتازيا! لقد بدأت رحلتك.'
where not exists (select 1 from badges where name = 'مستكشف كارتازيا');

insert into badges (name, icon, xp_required, description)
select 'صائد الكنوز', 'paid', 500, 'لقد اشتريت أول بطاقة لك!'
where not exists (select 1 from badges where name = 'صائد الكنوز');
