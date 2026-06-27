import type { FaqItem, FaqSection } from "./faq-data";

type Props = {
  sections?: FaqSection[];
  items?: FaqItem[];
  idPrefix?: string;
};

export function FaqList({ sections, items, idPrefix = "faq" }: Props) {
  if (sections) {
    return (
      <div className="faq-sections">
        {sections.map((section) => (
          <section className="faq-group" key={section.title}>
            <h2 className="faq-group-title">{section.title}</h2>
            <FaqList items={section.items} idPrefix={`${idPrefix}-${section.title.toLowerCase()}`} />
          </section>
        ))}
      </div>
    );
  }

  if (!items?.length) {
    return null;
  }

  return (
    <div className="faq-list">
      {items.map((item, index) => {
        const id = `${idPrefix}-${index + 1}`;
        return (
          <details className="faq-item" key={item.question} id={id}>
            <summary>{item.question}</summary>
            <div className="faq-answer">
              <p>{item.answer}</p>
            </div>
          </details>
        );
      })}
    </div>
  );
}
