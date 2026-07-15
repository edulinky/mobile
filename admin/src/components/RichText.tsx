"use client";

import {useEditor, EditorContent, Editor} from "@tiptap/react";
import StarterKit from "@tiptap/starter-kit";
import Link from "@tiptap/extension-link";
import {useEffect} from "react";

/**
 * Rich-text editor for announcement emails.
 *
 * Deliberately a small toolbar: email clients render a narrow, inconsistent
 * subset of HTML/CSS, so offering fonts, colours and tables would produce mail
 * that looks broken in half the inboxes it reaches. Bold/italic, headings,
 * lists, quote, link — everything here survives Gmail, Outlook and Apple Mail.
 *
 * The output is sanitised server-side against an allowlist regardless of what
 * this produces.
 */
export function RichText({
  onChange,
}: {
  /** Emits both the HTML and a plain-text fallback (many clients force it). */
  onChange: (html: string, text: string) => void;
}) {
  const editor = useEditor({
    immediatelyRender: false, // Next SSR
    extensions: [
      StarterKit.configure({
        heading: {levels: [1, 2, 3]},
        codeBlock: false,
        horizontalRule: false,
      }),
      Link.configure({openOnClick: false, autolink: true}),
    ],
    editorProps: {
      attributes: {class: "prose-editor"},
    },
  });

  useEffect(() => {
    if (!editor) return;
    const emit = () => onChange(editor.getHTML(), editor.getText());
    editor.on("update", emit);
    return () => {
      editor.off("update", emit);
    };
  }, [editor, onChange]);

  if (!editor) return <div className="meta">Loading editor…</div>;

  return (
    <div className="rte">
      <Toolbar editor={editor} />
      <EditorContent editor={editor} />
    </div>
  );
}

function Toolbar({editor}: {editor: Editor}) {
  const btn = (
    label: string,
    isActive: boolean,
    action: () => void,
    title: string
  ) => (
    <button
      type="button"
      title={title}
      className={`rte-btn ${isActive ? "active" : ""}`}
      onMouseDown={(e) => e.preventDefault()} // keep the selection
      onClick={action}
    >
      {label}
    </button>
  );

  return (
    <div className="rte-toolbar">
      {btn("B", editor.isActive("bold"), () => editor.chain().focus().toggleBold().run(), "Bold")}
      {btn("I", editor.isActive("italic"), () => editor.chain().focus().toggleItalic().run(), "Italic")}
      {btn("S", editor.isActive("strike"), () => editor.chain().focus().toggleStrike().run(), "Strikethrough")}
      <span className="rte-sep" />
      {btn("H1", editor.isActive("heading", {level: 1}), () => editor.chain().focus().toggleHeading({level: 1}).run(), "Heading 1")}
      {btn("H2", editor.isActive("heading", {level: 2}), () => editor.chain().focus().toggleHeading({level: 2}).run(), "Heading 2")}
      <span className="rte-sep" />
      {btn("• List", editor.isActive("bulletList"), () => editor.chain().focus().toggleBulletList().run(), "Bullet list")}
      {btn("1. List", editor.isActive("orderedList"), () => editor.chain().focus().toggleOrderedList().run(), "Numbered list")}
      {btn("❝", editor.isActive("blockquote"), () => editor.chain().focus().toggleBlockquote().run(), "Quote")}
      <span className="rte-sep" />
      {btn(
        "Link",
        editor.isActive("link"),
        () => {
          if (editor.isActive("link")) {
            editor.chain().focus().unsetLink().run();
            return;
          }
          const url = window.prompt("Link URL (https://…)");
          if (!url) return;
          editor.chain().focus().setLink({href: url}).run();
        },
        "Link"
      )}
    </div>
  );
}
