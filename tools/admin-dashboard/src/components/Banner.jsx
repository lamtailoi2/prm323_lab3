export default function Banner({ text }) {
  if (!text) return null;
  return (
    <div className="banner" role="alert">
      {text}
    </div>
  );
}
